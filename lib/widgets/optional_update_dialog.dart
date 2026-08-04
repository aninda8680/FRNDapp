import 'package:flutter/material.dart';
import '../services/update_download_service.dart';
import 'update_progress_dialog.dart';

/// A dismissible dialog that suggests an optional update to the user.
class OptionalUpdateDialog extends StatelessWidget {
  final String latestVersion;
  final String playStoreUrl;

  const OptionalUpdateDialog({
    super.key,
    required this.latestVersion,
    required this.playStoreUrl,
  });

  void _startUpdate(BuildContext context) {
    // Start download via the persistent singleton service
    UpdateDownloadService().start(url: playStoreUrl, version: latestVersion);

    // Close this suggestion dialog so user can keep using the app
    Navigator.of(context).pop();

    // Show a non-blocking progress dialog (user can dismiss it anytime)
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (ctx) => UpdateProgressDialog(
        apkUrl: playStoreUrl,
        version: latestVersion,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Available'),
      content: Text(
          'Version $latestVersion is now available. The download runs in the background — you can keep using the app while it downloads.'),
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
