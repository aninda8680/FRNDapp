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
    if (!context.mounted) return;

    // Pop this dialog first, then show the download progress dialog.
    // We must NOT pop before showDialog — doing so invalidates the context,
    // causes UpdateProgressDialog to dispose immediately, which triggers
    // AppUpdater().cancel() and leaves a corrupt partial APK on disk.
    Navigator.of(context).pop();

    // Use the root navigator to ensure the dialog survives any inner navigators.
    await showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
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
