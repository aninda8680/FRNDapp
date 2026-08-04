import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

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

  /// Downloads the APK for [version] from [url] and installs it.
  ///
  /// Smart caching behaviour:
  /// - If the APK for this [version] is already fully downloaded → skip download, open installer immediately.
  /// - If a partial download exists → resume from where it stopped (Range request).
  /// - Only re-downloads if the file is missing or corrupted.
  Future<void> downloadAndInstall({
    required String url,
    required String version,
    required void Function(int received, int total) onProgress,
  }) async {
    // Request storage permission on Android < 10
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (status.isDenied) await Permission.storage.request();
    }

    _cancelToken = CancelToken();

    final filePath = await _getVersionedFilePath(version);
    final file = File(filePath);

    // ── Step 1: Get remote file size (resolves GitHub redirect too) ──
    final remoteSize = await _fetchRemoteSize(url);

    // ── Step 2: Check if we already have a complete download ──
    final localSize = file.existsSync() ? file.lengthSync() : 0;

    if (remoteSize > 0 && localSize == remoteSize) {
      // Already fully downloaded — report 100% and skip straight to install
      onProgress(remoteSize, remoteSize);
    } else {
      // If remoteSize is unknown (HEAD failed), wipe any partial file.
      // Resuming into an unknown remote size risks appending into a corrupt file.
      if (remoteSize == 0 && file.existsSync()) {
        await file.delete();
      }

      // ── Step 3: Download (resume if partial, fresh if remoteSize unknown) ──
      await _download(
        url: url,
        filePath: filePath,
        localSize: remoteSize == 0 ? 0 : localSize,
        remoteSize: remoteSize,
        onProgress: onProgress,
      );

      // ── Step 3a: Verify the downloaded file is complete ──
      final downloadedSize = file.existsSync() ? file.lengthSync() : 0;
      if (remoteSize > 0 && downloadedSize != remoteSize) {
        // File is incomplete/corrupt — delete it so the next attempt re-downloads
        await file.delete();
        throw Exception(
          'Download incomplete: got $downloadedSize bytes, expected $remoteSize. '
          'Please try again.',
        );
      }

      // Clean up APKs from older versions to free space
      await _deleteOldVersionApks(version, filePath);
    }

    // ── Step 4: Open the system APK installer ──
    final result = await OpenFilex.open(filePath);
    if (result.type != ResultType.done) {
      throw Exception('Installer could not be opened: ${result.message}');
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
          // Resume from where we left off if partial download exists
          if (isResume) 'Range': 'bytes=$localSize-',
        },
      ),
    );
  }

  /// Sends a HEAD request to resolve the final redirect URL and read Content-Length.
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

  void cancel() {
    _cancelToken?.cancel('User cancelled');
    _cancelToken = null;
  }
}
