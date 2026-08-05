import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/update_download_service.dart';
import '../screens/blocking_update_screen.dart';
import '../screens/splash_version_screen.dart';

/// A dialog that suggests an optional update to the user.
///
/// "Later" → dismisses dialog and proceeds to the app normally.
///
/// "Update" → transitions to [DownloadState.updating] (blocking state),
///   closes this dialog, and pushes [BlockingUpdateScreen] via the root
///   navigator. The user CANNOT return to the app until the update is
///   installed or fails (there is no dismiss affordance on [BlockingUpdateScreen]).
///
/// Bug fix: the previous implementation dismissed this dialog and showed a
/// [barrierDismissible: true] progress dialog, allowing the user to tap outside
/// and use the app freely. That loophole is now closed.
class OptionalUpdateDialog extends StatelessWidget {
  final String latestVersion;
  final String playStoreUrl;
  final String? sha256;

  const OptionalUpdateDialog({
    super.key,
    required this.latestVersion,
    required this.playStoreUrl,
    this.sha256,
  });

  void _startUpdate(BuildContext context) async {
    // ── iOS Fallback ────────────────────────────────────────────────────────
    // iOS does not support APK sideloading. Open the store link directly.
    if (Platform.isIOS) {
      final uri = Uri.tryParse(playStoreUrl);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    // ── Android Flow ────────────────────────────────────────────────────────
    // Warn if on cellular data before starting the download.
    final proceed =
        await SplashVersionScreen.confirmCellularDownload(context);
    if (!proceed || !context.mounted) return;

    // 1. Start download in blocking mode (state → DownloadState.updating).
    UpdateDownloadService().start(
      url: playStoreUrl,
      version: latestVersion,
      sha256: sha256,
      blocking: true,
    );

    // 2. Close this suggestion dialog.
    Navigator.of(context).pop();

    // 3. Push the non-dismissible blocking screen via root navigator so it
    //    sits above any nested navigator or route in the app.
    BlockingUpdateScreen.show(
      context: context,
      apkUrl: playStoreUrl,
      version: latestVersion,
      sha256: sha256,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Available'),
      content: Text(
        'Version $latestVersion is now available. '
        'Update now for the latest features and improvements.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Later'),
        ),
        ElevatedButton(
          onPressed: () => _startUpdate(context),
          child: const Text('Update'),
        ),
      ],
    );
  }
}
