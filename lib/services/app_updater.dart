import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

/// Maximum age of a partial download before it is discarded and re-started.
/// This prevents corrupted or stale resume sessions from GitHub's time-limited
/// CDN URLs being reused after days of inactivity.
const Duration _kPartialFileMaxAge = Duration(hours: 24);

/// Maximum number of redirect re-resolution attempts when a resumed Range
/// request receives a 4xx (e.g. 403 on an expired CDN token).
const int _kMaxRedirectRetries = 2;

/// Handles the actual APK download (with resume), SHA-256 integrity check,
/// install-permission verification, and install-intent launch.
///
/// Design notes on FLAG_ACTIVITY_NEW_TASK:
/// ──────────────────────────────────────
/// [installApk] is intentionally NOT called from within the foreground service
/// task handler (UpdateForegroundTask). Instead, [UpdateDownloadService]
/// transitions to [DownloadState.done] and [BlockingUpdateScreen] — which runs
/// in the Activity/Flutter-UI context — calls [installApk].
///
/// This means [OpenFilex] executes from an Activity context, so
/// FLAG_ACTIVITY_NEW_TASK is NOT required and the install sheet appears
/// immediately without any OS restrictions.
///
/// If a background-completed download needs to be installed after the user
/// returns to the foreground, [main.dart]'s [AppLifecycleObserver] detects the
/// [AppLifecycleState.resumed] event and [BlockingUpdateScreen] re-checks state,
/// triggering the install at that point.
class AppUpdater {
  static final AppUpdater _instance = AppUpdater._internal();
  factory AppUpdater() => _instance;
  AppUpdater._internal();

  CancelToken? _cancelToken;

  final Dio _dio = Dio(BaseOptions(
    // Critical: GitHub release URLs redirect to CDN — must follow
    followRedirects: true,
    maxRedirects: 5,
    receiveTimeout: const Duration(minutes: 15),
    connectTimeout: const Duration(seconds: 30),
  ));

  // ── Public API ────────────────────────────────────────────────────────────

  /// Downloads the APK for [version] from [url], verifies [expectedSha256]
  /// (if provided), and resolves without error when the file is ready to
  /// install. Does NOT call [installApk] — that is the caller's responsibility
  /// (see design note above).
  ///
  /// Smart caching behaviour:
  /// • Fully downloaded → skip download, re-verify hash, resolve.
  /// • Partial download < 24 h old → resume with Range header.
  /// • Partial download ≥ 24 h old → delete and restart (stale CDN session).
  /// • remoteSize unknown (HEAD failed) → wipe any partial and re-download.
  Future<void> downloadAndInstall({
    required String url,
    required String version,
    String? expectedSha256,
    required void Function(int received, int total) onProgress,
  }) async {
    // Request legacy storage permission on Android < 10
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (status.isDenied) await Permission.storage.request();
    }

    _cancelToken = CancelToken();

    final filePath = await _getVersionedFilePath(version);
    final file = File(filePath);

    // ── Step 1: Remote size (resolves GitHub redirect too) ────────────────
    final remoteSize = await _fetchRemoteSize(url);

    // ── Step 2: Local state ───────────────────────────────────────────────
    final localSize = file.existsSync() ? file.lengthSync() : 0;
    final localAge = file.existsSync()
        ? DateTime.now().difference(
            await file.lastModified(),
          )
        : Duration.zero;

    final isStalePartial = localSize > 0 &&
        localSize < (remoteSize > 0 ? remoteSize : localSize + 1) &&
        localAge > _kPartialFileMaxAge;

    if (isStalePartial) {
      // Stale partial — delete so next step does a full fresh download.
      await file.delete();
    }

    if (remoteSize > 0 && localSize == remoteSize) {
      // ── Already fully downloaded ─────────────────────────────────────────
      onProgress(remoteSize, remoteSize);
      // Still verify integrity in case the file was written by a previous run
      // that didn't have sha256 checking.
      await _verifyIntegrity(file, expectedSha256);
    } else {
      if (remoteSize == 0 && file.existsSync()) {
        // HEAD failed — can't safely resume; wipe the partial.
        await file.delete();
      }

      // ── Step 3: Download (fresh or resumed) ──────────────────────────────
      final freshLocalSize = file.existsSync() ? file.lengthSync() : 0;
      await _downloadWithRedirectRetry(
        originalUrl: url,
        filePath: filePath,
        localSize: remoteSize == 0 ? 0 : freshLocalSize,
        remoteSize: remoteSize,
        onProgress: onProgress,
        redirRetries: 0,
      );

      // ── Step 3a: Size sanity check ────────────────────────────────────────
      final downloadedSize = file.existsSync() ? file.lengthSync() : 0;
      if (remoteSize > 0 && downloadedSize != remoteSize) {
        await _deleteIfExists(file);
        throw Exception(
          'Download incomplete: got $downloadedSize bytes, expected $remoteSize bytes. '
          'Please retry.',
        );
      }

      // ── Step 3b: SHA-256 integrity verification ───────────────────────────
      await _verifyIntegrity(file, expectedSha256);

      // ── Step 3c: Clean up old version APKs ───────────────────────────────
      await _deleteOldVersionApks(version, filePath);
    }
    // Caller (BlockingUpdateScreen via AppLifecycleState.resumed) will call
    // installApk() when the UI is confirmed to be in the foreground.
  }

  /// Opens the system APK installer for the already-downloaded APK at [version].
  ///
  /// Must be called from Activity/UI context (i.e. from Flutter widget code,
  /// NOT from inside a foreground service task handler callback).
  ///
  /// Checks "Install unknown apps" permission first; requests it if missing.
  Future<void> installApk({required String version}) async {
    final filePath = await _getVersionedFilePath(version);
    final file = File(filePath);

    if (!file.existsSync()) {
      throw Exception(
        'APK file not found. The download may have been lost. Please retry.',
      );
    }

    // ── Install-permission pre-check ──────────────────────────────────────
    // REQUEST_INSTALL_PACKAGES in the manifest is required but not sufficient —
    // the user must also grant per-app "Install unknown apps" in Settings on
    // API 26+. Without this grant OpenFilex fails silently.
    if (Platform.isAndroid) {
      final canInstall = await Permission.requestInstallPackages.isGranted;
      if (!canInstall) {
        final granted =
            await Permission.requestInstallPackages.request().isGranted;
        if (!granted) {
          throw Exception(
            'Install permission denied — please allow "Install unknown apps" '
            'for FrndBuzz in Settings, then retry.',
          );
        }
      }
    }

    final result = await OpenFilex.open(filePath);
    if (result.type != ResultType.done) {
      throw Exception(
        'Installer could not be opened: ${result.message}. '
        'If the problem persists, try restarting the app.',
      );
    }
  }

  void cancel() {
    _cancelToken?.cancel('User cancelled');
    _cancelToken = null;
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Downloads the file, retrying up to [_kMaxRedirectRetries] times by
  /// re-resolving the redirect from [originalUrl] when the server returns a
  /// 4xx on a Range request (e.g. expired GitHub CDN token).
  Future<void> _downloadWithRedirectRetry({
    required String originalUrl,
    required String filePath,
    required int localSize,
    required int remoteSize,
    required void Function(int received, int total) onProgress,
    required int redirRetries,
  }) async {
    try {
      await _download(
        url: originalUrl,
        filePath: filePath,
        localSize: localSize,
        remoteSize: remoteSize,
        onProgress: onProgress,
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      // 403 / 401 on a resumed request almost always means the CDN token
      // embedded in the redirect target has expired.
      if (localSize > 0 &&
          (statusCode == 403 || statusCode == 401) &&
          redirRetries < _kMaxRedirectRetries) {
        // Re-resolve the redirect from the original GitHub URL to get a fresh
        // signed CDN URL, then retry the Range request.
        final freshUrl = await _resolveFinalUrl(originalUrl);
        await _downloadWithRedirectRetry(
          originalUrl: freshUrl,
          filePath: filePath,
          localSize: localSize,
          remoteSize: remoteSize,
          onProgress: onProgress,
          redirRetries: redirRetries + 1,
        );
      } else {
        _rethrowDescriptive(e);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _download({
    required String url,
    required String filePath,
    required int localSize,
    required int remoteSize,
    required void Function(int received, int total) onProgress,
  }) async {
    final isResume = localSize > 0 && remoteSize > 0 && localSize < remoteSize;

    await _dio.download(
      url,
      filePath,
      cancelToken: _cancelToken,
      deleteOnError: false, // Keep partial file so we can resume next time
      onReceiveProgress: (received, total) {
        final actualReceived = received + (isResume ? localSize : 0);
        final actualTotal =
            remoteSize > 0 ? remoteSize : (total > 0 ? total : -1);
        onProgress(actualReceived, actualTotal);
      },
      options: Options(
        // ResponseType.stream is required for correct byte-range resuming.
        // ResponseType.bytes would overwrite the file from the start,
        // producing a corrupt APK when a partial file already exists.
        responseType: ResponseType.stream,
        headers: {
          'Accept': 'application/octet-stream',
          if (isResume) 'Range': 'bytes=$localSize-',
        },
      ),
    );
  }

  /// Follows redirects and returns the final resolved URL (the CDN URL).
  /// Used for re-resolution when a 403 occurs on an expired signed URL.
  Future<String> _resolveFinalUrl(String url) async {
    try {
      String resolved = url;
      // Disable automatic redirect following so we can read the Location header.
      final tempDio = Dio(BaseOptions(
        followRedirects: false,
        maxRedirects: 0,
        connectTimeout: const Duration(seconds: 15),
      ));
      for (int i = 0; i < 5; i++) {
        try {
          await tempDio.head<dynamic>(resolved,
              options: Options(
                headers: {'Accept': 'application/octet-stream'},
                validateStatus: (s) => s != null && s < 400,
              ));
          break; // No redirect → we're at the final URL
        } on DioException catch (e) {
          final location = e.response?.headers.value('location');
          if (location != null &&
              (e.response?.statusCode ?? 0) >= 300 &&
              (e.response?.statusCode ?? 0) < 400) {
            resolved = location;
          } else {
            break;
          }
        }
      }
      return resolved;
    } catch (_) {
      return url; // Fall back to original URL on failure
    }
  }

  /// Sends a HEAD request to the final URL to read Content-Length.
  Future<int> _fetchRemoteSize(String url) async {
    try {
      final response = await _dio.head<dynamic>(
        url,
        options: Options(
          headers: {'Accept': 'application/octet-stream'},
          followRedirects: true,
          maxRedirects: 5,
        ),
      );
      final raw = response.headers.value('content-length');
      return raw != null ? (int.tryParse(raw) ?? 0) : 0;
    } catch (_) {
      return 0;
    }
  }

  /// Verifies the file's SHA-256 digest against [expectedSha256].
  ///
  /// If [expectedSha256] is null, skips verification (backwards-compatible).
  /// If the digests don't match, deletes the corrupt file and throws.
  Future<void> _verifyIntegrity(File file, String? expectedSha256) async {
    if (expectedSha256 == null || expectedSha256.isEmpty) return;

    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    // Normalise to lowercase hex for comparison
    final actual = digest.toString().toLowerCase();
    final expected = expectedSha256.toLowerCase();

    if (actual != expected) {
      await _deleteIfExists(file);
      throw Exception(
        'Download verification failed — the file was corrupted in transit '
        '(expected SHA-256 $expected, got $actual). Please retry.',
      );
    }
  }

  /// Returns a version-stamped path like `.../update_v1.0.3.apk`
  Future<String> _getVersionedFilePath(String version) async {
    Directory? dir;
    try {
      dir = await getExternalStorageDirectory();
    } catch (_) {
      dir = null;
    }
    dir ??= await getApplicationDocumentsDirectory();
    return '${dir.path}/update_v$version.apk';
  }

  /// Deletes APKs from previous versions to reclaim disk space.
  Future<void> _deleteOldVersionApks(
      String currentVersion, String currentPath) async {
    try {
      final file = File(currentPath);
      final dir = file.parent;
      if (!dir.existsSync()) return;

      final apks = dir
          .listSync()
          .whereType<File>()
          .where((f) =>
              f.path.contains('update_v') &&
              f.path.endsWith('.apk') &&
              f.path != currentPath)
          .toList();

      for (final old in apks) {
        await old.delete();
      }
    } catch (_) {
      // Non-critical — ignore cleanup failures
    }
  }

  Future<void> _deleteIfExists(File file) async {
    try {
      if (file.existsSync()) await file.delete();
    } catch (_) {}
  }

  /// Converts a [DioException] into a user-readable message.
  Never _rethrowDescriptive(DioException e) {
    final code = e.response?.statusCode;
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      throw Exception(
        'Network timeout — check your internet connection and retry.',
      );
    }
    if (e.type == DioExceptionType.connectionError) {
      throw Exception(
        'Network error — no internet connection. Please connect and retry.',
      );
    }
    throw Exception(
      'Download failed (HTTP $code). Please retry.',
    );
  }
}
