import 'package:flutter/material.dart';
import 'update_progress_dialog.dart';

/// A dismissible dialog that suggests an optional update to the user.
class OptionalUpdateDialog extends StatelessWidget {
  /// The latest available version string to display.
  final String latestVersion;

  /// The APK download URL from Firestore.
  final String playStoreUrl;

  const OptionalUpdateDialog({
    super.key,
    required this.latestVersion,
    required this.playStoreUrl,
  });

  Future<void> _startUpdateAndPop(BuildContext context) async {
    if (context.mounted) {
      Navigator.of(context).pop();
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UpdateProgressDialog(
        apkUrl: playStoreUrl,
        version: latestVersion, // version-stamped caching
      ),
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
          onPressed: () => _startUpdateAndPop(context),
          child: const Text('Update'),
        ),
      ],
    );
  }
}
