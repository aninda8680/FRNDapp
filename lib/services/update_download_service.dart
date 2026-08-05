import 'dart:async';
import 'package:flutter/foundation.dart';
import 'app_updater.dart';
import 'update_foreground_task.dart';

/// The lifecycle state of the APK download/install process.
///
/// Distinction between [downloading] and [updating] matters for the UI:
///
/// • [downloading] — background optional download started but the user has NOT
///   explicitly committed. The UI may show a non-blocking progress banner and
///   the user can continue using the app.
///
/// • [updating]   — the user tapped "Update" on either the force-update or
///   optional-update dialog. The UI MUST present a full-screen blocking screen
///   (PopScope canPop: false). No dismiss affordance is shown.
///
/// • [done]       — download finished and size/hash verified. Install intent
///   will be triggered by [BlockingUpdateScreen] once the app is foregrounded.
///
/// • [failed]     — non-recoverable error (network failure, hash mismatch, etc.).
///   UI shows the descriptive [errorMessage] and a Retry button.
enum DownloadState { idle, downloading, updating, done, failed }

/// A singleton service that owns the APK download lifecycle.
///
/// UI widgets observe [progress], [downloadedBytes], [totalBytes], [state], and
/// [errorMessage] via [ValueNotifier]s. The download itself runs inside a
/// foreground service (via [UpdateForegroundTask]) so it survives OEM background
/// killers (MIUI Autostart, Samsung Deep Sleep, etc.).
class UpdateDownloadService {
  static final UpdateDownloadService _instance =
      UpdateDownloadService._internal();
  factory UpdateDownloadService() => _instance;
  UpdateDownloadService._internal();

  // ── Public observables ────────────────────────────────────────────────────

  final ValueNotifier<double> progress = ValueNotifier(0.0);
  final ValueNotifier<int> downloadedBytes = ValueNotifier(0);
  final ValueNotifier<int> totalBytes = ValueNotifier(0);
  final ValueNotifier<DownloadState> state = ValueNotifier(DownloadState.idle);

  /// Human-readable error message, set only when [state] == [DownloadState.failed].
  ///
  /// Messages are deliberately descriptive so users can self-diagnose without
  /// remote logs: e.g. "Network error — no internet connection",
  /// "Download verification failed — file was corrupted. Please retry.",
  /// "Install permission denied — please allow 'Install unknown apps' for FrndBuzz."
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);

  // ── Internal state ────────────────────────────────────────────────────────

  String? _currentVersion;
  String? get currentVersion => _currentVersion;

  /// True when the user has committed to updating (blocking UI is active).
  bool get isBlocking => state.value == DownloadState.updating;

  bool get isActive =>
      state.value == DownloadState.downloading ||
      state.value == DownloadState.updating ||
      state.value == DownloadState.done;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Starts (or resumes) the download for [version] from [url].
  ///
  /// [blocking] = true  → transitions to [DownloadState.updating].
  ///               The [BlockingUpdateScreen] will be pushed by the caller.
  ///
  /// [blocking] = false → transitions to [DownloadState.downloading].
  ///               A non-blocking background download; UI may show a banner.
  ///
  /// Safe to call multiple times — idempotent for the same version.
  void start({
    required String url,
    required String version,
    String? sha256,
    bool blocking = true,
  }) {
    // Already downloading/updating this exact version — do nothing.
    if ((state.value == DownloadState.downloading ||
            state.value == DownloadState.updating) &&
        _currentVersion == version) {
      // If the caller now wants blocking mode but we started non-blocking,
      // upgrade the state so the BlockingUpdateScreen shows correctly.
      if (blocking && state.value == DownloadState.downloading) {
        state.value = DownloadState.updating;
      }
      return;
    }

    _currentVersion = version;
    state.value = blocking ? DownloadState.updating : DownloadState.downloading;
    progress.value = 0.0;
    downloadedBytes.value = 0;
    totalBytes.value = 0;
    errorMessage.value = null;

    _run(url: url, version: version, sha256: sha256);
  }

  Future<void> _run({
    required String url,
    required String version,
    String? sha256,
  }) async {
    try {
      await UpdateForegroundTask.startForegroundDownload(
        url: url,
        version: version,
        sha256: sha256,
      );
      // AppUpdater finishes inside the foreground task handler; it calls
      // UpdateForegroundTask.onProgressFromTask which routes back here.
      // The final state transition (done/failed) is also driven from there.
    } catch (e) {
      _onFailed('Unexpected error starting download: $e');
    }
  }

  /// Called by [UpdateForegroundTask] with live progress data.
  void onProgress(int received, int total) {
    downloadedBytes.value = received;
    totalBytes.value = total;
    if (total > 0) {
      progress.value = (received / total).clamp(0.0, 1.0);
    }
  }

  /// Called by [UpdateForegroundTask] when download + verification succeeded.
  /// The actual install intent is triggered by [BlockingUpdateScreen].
  void onDownloadDone() {
    progress.value = 1.0;
    state.value = DownloadState.done;
  }

  /// Called by [UpdateForegroundTask] when the download fails.
  void onFailed(String message) => _onFailed(message);

  void _onFailed(String message) {
    state.value = DownloadState.failed;
    errorMessage.value = message;
  }

  void reset() {
    AppUpdater().cancel();
    UpdateForegroundTask.stopForegroundDownload();
    state.value = DownloadState.idle;
    progress.value = 0.0;
    downloadedBytes.value = 0;
    totalBytes.value = 0;
    errorMessage.value = null;
    _currentVersion = null;
  }

  void retry({required String url, required String version, String? sha256}) {
    reset();
    start(url: url, version: version, sha256: sha256);
  }
}
