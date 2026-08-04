import 'dart:async';
import 'package:flutter/foundation.dart';
import 'app_updater.dart';

/// The state of the background update download.
enum DownloadState { idle, downloading, done, failed }

/// A singleton service that owns the APK download lifecycle.
///
/// The download continues in the background even if the progress UI is
/// dismissed. Widgets can observe [progress] and [state] via ValueNotifier.
class UpdateDownloadService {
  static final UpdateDownloadService _instance =
      UpdateDownloadService._internal();
  factory UpdateDownloadService() => _instance;
  UpdateDownloadService._internal();

  final ValueNotifier<double> progress = ValueNotifier(0.0);
  final ValueNotifier<DownloadState> state =
      ValueNotifier(DownloadState.idle);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);

  String? _currentVersion;
  String? get currentVersion => _currentVersion;

  bool get isActive =>
      state.value == DownloadState.downloading ||
      state.value == DownloadState.done;

  /// Starts download if not already running for this version.
  /// Safe to call multiple times — idempotent for the same version.
  void start({required String url, required String version}) {
    if (state.value == DownloadState.downloading &&
        _currentVersion == version) {
      return; // Already downloading this version
    }

    _currentVersion = version;
    state.value = DownloadState.downloading;
    progress.value = 0.0;
    errorMessage.value = null;

    _run(url: url, version: version);
  }

  Future<void> _run({required String url, required String version}) async {
    try {
      await AppUpdater().downloadAndInstall(
        url: url,
        version: version,
        onProgress: (received, total) {
          if (total > 0) {
            progress.value = (received / total).clamp(0.0, 1.0);
          }
        },
      );
      // downloadAndInstall already opens the installer on success.
      state.value = DownloadState.done;
    } catch (e) {
      state.value = DownloadState.failed;
      errorMessage.value = 'Download failed. Tap to retry.';
    }
  }

  void reset() {
    AppUpdater().cancel();
    state.value = DownloadState.idle;
    progress.value = 0.0;
    errorMessage.value = null;
    _currentVersion = null;
  }

  void retry({required String url, required String version}) {
    reset();
    start(url: url, version: version);
  }
}
