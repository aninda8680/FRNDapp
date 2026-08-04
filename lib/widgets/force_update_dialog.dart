import 'package:flutter/material.dart';
import '../services/update_download_service.dart';
import 'update_progress_dialog.dart';

/// A non-dismissible dialog that forces the user to update the app.
class ForceUpdateDialog extends StatelessWidget {
  final String playStoreUrl;
  final String latestVersion;

  const ForceUpdateDialog({
    super.key,
    required this.playStoreUrl,
    required this.latestVersion,
  });

  void _startUpdate(BuildContext context) {
    // Start download via the persistent singleton — safe to call multiple times
    UpdateDownloadService().start(url: playStoreUrl, version: latestVersion);

    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false, // Force update: user cannot dismiss
      builder: (ctx) => UpdateProgressDialog(
        apkUrl: playStoreUrl,
        version: latestVersion,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('Update Required'),
        content: const Text(
            'A new version of the app is required to continue. Please update to the latest version.'),
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
