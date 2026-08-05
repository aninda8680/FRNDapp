import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/update_download_service.dart';
import '../screens/blocking_update_screen.dart';
import '../screens/splash_version_screen.dart';

/// A non-dismissible dialog that forces the user to update the app.
///
/// Tapping "Update Now" starts the download in blocking mode and pushes
/// [BlockingUpdateScreen] via the root navigator. [PopScope(canPop: false)]
/// prevents the back button from bypassing this dialog before the user taps.
class ForceUpdateDialog extends StatelessWidget {
  final String playStoreUrl;
  final String latestVersion;
  final String? sha256;

  const ForceUpdateDialog({
    super.key,
    required this.playStoreUrl,
    required this.latestVersion,
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
    // Even for forced updates, warn on cellular so users aren't surprised
    // by a large data charge. They cannot skip the update, but they can
    // choose to wait for Wi-Fi before confirming.
    final proceed =
        await SplashVersionScreen.confirmCellularDownload(context);
    if (!proceed || !context.mounted) return;

    // Start download via the persistent singleton — safe to call multiple times.
    UpdateDownloadService().start(
      url: playStoreUrl,
      version: latestVersion,
      sha256: sha256,
      blocking: true,
    );

    // Close the force-update alert and push the blocking full-screen UI.
    Navigator.of(context).pop();

    BlockingUpdateScreen.show(
      context: context,
      apkUrl: playStoreUrl,
      version: latestVersion,
      sha256: sha256,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // User cannot back out of a forced update prompt.
      child: AlertDialog(
        title: const Text('Update Required'),
        content: const Text(
          'A new version of FrndBuzz is required to continue. '
          'Please update to the latest version.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => _startUpdate(context),
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }
}
