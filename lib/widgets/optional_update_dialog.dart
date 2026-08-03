import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'update_progress_dialog.dart';

/// A dismissible dialog that suggests an optional update to the user.
class OptionalUpdateDialog extends StatelessWidget {
  /// The latest available version string to display.
  final String latestVersion;

  /// The store URL to redirect the user to.
  final String playStoreUrl;

  const OptionalUpdateDialog({
    super.key,
    required this.latestVersion,
    required this.playStoreUrl,
  });

  Future<void> _launchStoreAndPop(BuildContext context) async {
    if (context.mounted) {
      Navigator.of(context).pop();
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UpdateProgressDialog(apkUrl: playStoreUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Available'),
      content: Text(
          'Version $latestVersion is now available. Would you like to update now?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Later'),
        ),
        ElevatedButton(
          onPressed: () => _launchStoreAndPop(context),
          child: const Text('Update'),
        ),
      ],
    );
  }
}
