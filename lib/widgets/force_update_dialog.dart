import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A non-dismissible dialog that forces the user to update the app.
class ForceUpdateDialog extends StatelessWidget {
  /// The store URL to redirect the user to.
  final String playStoreUrl;

  const ForceUpdateDialog({
    super.key,
    required this.playStoreUrl,
  });

  Future<void> _launchStore() async {
    final uri = Uri.parse(playStoreUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
            onPressed: _launchStore,
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }
}
