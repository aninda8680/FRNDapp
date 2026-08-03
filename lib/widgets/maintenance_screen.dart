import 'package:flutter/material.dart';

/// A full-screen block shown when the app is in maintenance mode.
class MaintenanceScreen extends StatelessWidget {
  /// Callback to retry the version check.
  final VoidCallback? onRetry;

  const MaintenanceScreen({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevents navigating away
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.build_circle_outlined,
                  size: 80,
                  color: Colors.orange,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Under Maintenance',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'We are currently performing scheduled maintenance. Please check back later.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
