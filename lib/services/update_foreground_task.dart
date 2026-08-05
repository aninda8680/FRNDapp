import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'app_updater.dart';
import 'update_download_service.dart';

// ── Task event type keys ───────────────────────────────────────────────────

const _kEventProgress = 'progress';
const _kEventDone = 'done';
const _kEventFailed = 'failed';

const _kKeyReceived = 'received';
const _kKeyTotal = 'total';
const _kKeyMessage = 'message';

const _kKeyUrl = 'url';
const _kKeyVersion = 'version';
const _kKeySha256 = 'sha256';

/// Throttle foreground notification updates to every 2% to avoid spam.
const double _kNotifyThreshold = 0.02;

// ── Public API ─────────────────────────────────────────────────────────────

/// Manages the foreground-service lifecycle for OEM-safe APK downloads.
///
/// Why a foreground service?
/// ─────────────────────────
/// • MIUI (Xiaomi/Redmi/Poco): Has its own Autostart permission system on top
///   of Android's battery optimisation. A plain Dart async Future can be killed
///   within seconds of backgrounding. A foreground service with a persistent
///   notification is explicitly excluded from MIUI's aggressive process killer.
///
/// • Samsung OneUI: "Put unused apps to sleep" / "Deep sleeping apps" settings
///   can suspend background execution. A running foreground service prevents
///   this suspension for the duration of the download.
///
/// • Stock Android 10+: Background execution limits generally prevent starting
///   new work from a non-foreground context. A foreground service with a
///   declared notification bypasses these limits.
///
/// On install intent and FLAG_ACTIVITY_NEW_TASK:
/// ─────────────────────────────────────────────
/// [AppUpdater.installApk] is intentionally NOT called from within this task
/// handler. Once the download completes, [UpdateDownloadService] transitions to
/// [DownloadState.done]. The [BlockingUpdateScreen] — which runs in the
/// Flutter Activity context — detects this state change and calls installApk().
/// This ensures the install intent fires from Activity context, so
/// FLAG_ACTIVITY_NEW_TASK is NOT required and the system installer sheet
/// appears without restriction.
class UpdateForegroundTask {
  UpdateForegroundTask._();

  // v8 API: communication uses addTaskDataCallback / removeTaskDataCallback
  // instead of the old onReceiveTaskData stream.
  static DataCallback? _taskDataCallback;

  /// Initialises FlutterForegroundTask. Call once in [main()] before [runApp].
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'frnd_update_download',
        channelName: 'App Update Download',
        channelDescription:
            'Shows download progress when a new FrndBuzz update is available.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
    // Register the communication port so the task isolate can send data back.
    FlutterForegroundTask.initCommunicationPort();
  }

  /// Starts the foreground service and immediately sends download parameters
  /// to the task handler via [FlutterForegroundTask.sendDataToTask].
  static Future<void> startForegroundDownload({
    required String url,
    required String version,
    String? sha256,
  }) async {
    // Request notification permission on Android 13+ (API 33+)
    await FlutterForegroundTask.requestNotificationPermission();

    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }

    final serviceResult = await FlutterForegroundTask.startService(
      serviceId: 1001,
      notificationTitle: 'FrndBuzz Update',
      notificationText: 'Starting download…',
      // v8 API: NotificationIcon uses metaDataName (declared in AndroidManifest
      // via <meta-data>) instead of the old NotificationIconData/ResourceType.
      notificationIcon: const NotificationIcon(
        metaDataName: 'com.pravera.flutter_foreground_task.icon',
      ),
      callback: _startDownloadCallback,
    );

    if (serviceResult is ServiceRequestFailure) {
      // Service failed to start — fall back to plain async download.
      // This can happen if the user denied notification permission on Android
      // 13+, or if the device does not support foreground services. We still
      // run the download, just without the persistent notification protection.
      _runPlainDownload(url: url, version: version, sha256: sha256);
      return;
    }

    // v8 API: sendDataToTask is now void (not a Future), so no await.
    FlutterForegroundTask.sendDataToTask(<String, String?>{
      _kKeyUrl: url,
      _kKeyVersion: version,
      _kKeySha256: sha256,
    });

    // v8 API: listen for events from the task handler using addTaskDataCallback.
    _removeCallback();
    _taskDataCallback = _handleTaskEvent;
    FlutterForegroundTask.addTaskDataCallback(_taskDataCallback!);
  }

  /// Stops and destroys the foreground download service.
  static Future<void> stopForegroundDownload() async {
    _removeCallback();
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  static void _removeCallback() {
    if (_taskDataCallback != null) {
      FlutterForegroundTask.removeTaskDataCallback(_taskDataCallback!);
      _taskDataCallback = null;
    }
  }

  // ── Plain-async fallback (no foreground service) ───────────────────────────

  static void _runPlainDownload({
    required String url,
    required String version,
    String? sha256,
  }) {
    final svc = UpdateDownloadService();
    AppUpdater()
        .downloadAndInstall(
      url: url,
      version: version,
      expectedSha256: sha256,
      onProgress: (received, total) => svc.onProgress(received, total),
    )
        .then((_) => svc.onDownloadDone())
        .catchError((Object e) => svc.onFailed(
              e.toString().replaceFirst('Exception: ', ''),
            ));
  }

  // ── Task event handler (main isolate) ──────────────────────────────────────

  static void _handleTaskEvent(Object event) {
    if (event is! Map) return;
    final data = Map<String, dynamic>.from(event);
    final type = data['type'] as String?;
    final svc = UpdateDownloadService();

    switch (type) {
      case _kEventProgress:
        final received = data[_kKeyReceived] as int? ?? 0;
        final total = data[_kKeyTotal] as int? ?? 0;
        svc.onProgress(received, total);

      case _kEventDone:
        svc.onDownloadDone();
        stopForegroundDownload();

      case _kEventFailed:
        final msg = data[_kKeyMessage] as String? ?? 'Download failed.';
        svc.onFailed(msg);
        stopForegroundDownload();
    }
  }
}

// ── Task callback — runs in the foreground service isolate ─────────────────

/// Top-level entry point for the foreground service. Must be top-level and
/// annotated with @pragma('vm:entry-point') to survive tree-shaking.
@pragma('vm:entry-point')
void _startDownloadCallback() {
  FlutterForegroundTask.setTaskHandler(_DownloadTaskHandler());
}

// v8.17.0 TaskHandler signature:
//   onStart(DateTime timestamp, TaskStarter starter)
//   onRepeatEvent(DateTime timestamp)                  ← no SendPort
//   onDestroy(DateTime timestamp)                      ← no SendPort
//   onReceiveData(Object data)                         ← unchanged
class _DownloadTaskHandler extends TaskHandler {
  String? _url;
  String? _version;
  String? _sha256;
  double _lastNotifiedProgress = -1.0;

  /// Receives download parameters sent via FlutterForegroundTask.sendDataToTask().
  @override
  void onReceiveData(Object data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    _url = map[_kKeyUrl] as String?;
    _version = map[_kKeyVersion] as String?;
    _sha256 = map[_kKeySha256] as String?;

    if (_url != null && _version != null) {
      _runDownload();
    }
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Parameters arrive via onReceiveData after the service starts.
    // Nothing to do here.
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Not used — ForegroundTaskEventAction.nothing() disables repeat events.
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    AppUpdater().cancel();
  }

  void _runDownload() {
    AppUpdater()
        .downloadAndInstall(
      url: _url!,
      version: _version!,
      expectedSha256: _sha256,
      onProgress: (received, total) {
        // Throttle notification updates to avoid spam (every 2%)
        final pct = total > 0 ? received / total : 0.0;
        if (pct - _lastNotifiedProgress >= _kNotifyThreshold || pct >= 1.0) {
          _lastNotifiedProgress = pct;
          final pctInt = (pct * 100).toInt();
          FlutterForegroundTask.updateService(
            notificationTitle: 'FrndBuzz Update',
            notificationText: 'Downloading update… $pctInt%',
          );
        }
        // Relay progress to the main isolate
        FlutterForegroundTask.sendDataToMain(<String, dynamic>{
          'type': _kEventProgress,
          _kKeyReceived: received,
          _kKeyTotal: total,
        });
      },
    )
        .then((_) {
      FlutterForegroundTask.updateService(
        notificationTitle: 'FrndBuzz Update',
        notificationText: 'Download complete — tap to open app and install.',
      );
      FlutterForegroundTask.sendDataToMain(<String, dynamic>{
        'type': _kEventDone,
      });
    }).catchError((Object e) {
      FlutterForegroundTask.sendDataToMain(<String, dynamic>{
        'type': _kEventFailed,
        _kKeyMessage: e.toString().replaceFirst('Exception: ', ''),
      });
    });
  }
}
