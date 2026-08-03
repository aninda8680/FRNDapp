import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'update_progress_dialog.dart';

/// A non-dismissible dialog that forces the user to update the app.
class ForceUpdateDialog extends StatelessWidget {
  /// The store URL to redirect the user to.
  final String playStoreUrl;

  const ForceUpdateDialog({
    super.key,
    required this.playStoreUrl,
  });
  Future<void> _launchStore(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UpdateProgressDialog(apkUrl: playStoreUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Disables the back button
      child: AlertDialog(
        title: const Text('Update Required'),
        content: const Text(
            'A new version of the app is required to continue. Please update to the latest version.'),
        actions: [
          ElevatedButton(
            onPressed: () => _launchStore(context),
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }
}
