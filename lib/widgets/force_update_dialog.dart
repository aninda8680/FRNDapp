import 'package:flutter/material.dart';
import 'update_progress_dialog.dart';

/// A non-dismissible dialog that forces the user to update the app.
class ForceUpdateDialog extends StatelessWidget {
  /// The APK download URL from Firestore.
  final String playStoreUrl;

  /// The latest version string — used for version-stamped APK caching.
  final String latestVersion;

  const ForceUpdateDialog({
    super.key,
    required this.playStoreUrl,
    required this.latestVersion,
  });

  Future<void> _startUpdate(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UpdateProgressDialog(
        apkUrl: playStoreUrl,
        version: latestVersion,
      ),
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
            onPressed: () => _startUpdate(context),
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }
}
