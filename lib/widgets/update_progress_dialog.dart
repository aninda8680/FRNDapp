import 'package:flutter/material.dart';
import '../services/app_updater.dart';
import 'sketchy_progress_bar.dart';

class UpdateProgressDialog extends StatefulWidget {
  final String apkUrl;
  final String version;

  const UpdateProgressDialog({
    super.key,
    required this.apkUrl,
    required this.version,
  });

  @override
  State<UpdateProgressDialog> createState() => _UpdateProgressDialogState();
}

class _UpdateProgressDialogState extends State<UpdateProgressDialog> {
  double _progress = 0.0;
  bool _isDownloading = true;
  bool _isAlreadyCached = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  @override
  void dispose() {
    // Cancel in-flight download if user navigates away
    AppUpdater().cancel();
    super.dispose();
  }

  Future<void> _startDownload() async {
    try {
      await AppUpdater().downloadAndInstall(
        url: widget.apkUrl,
        version: widget.version,
        onProgress: (received, total) {
          if (!mounted) return;
          if (total > 0) {
            final progress = received / total;
            setState(() {
              // If already 100% on first callback, it was cached
              _isAlreadyCached = progress >= 1.0 && _progress == 0.0;
              _progress = progress.clamp(0.0, 1.0);
            });
          }
        },
      );
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _errorMessage = 'Download failed. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int percentage = (_progress * 100).toInt();

    String title;
    if (_errorMessage != null) {
      title = 'Download Failed';
    } else if (!_isDownloading) {
      title = 'Ready to Install';
    } else if (_isAlreadyCached) {
      title = 'Already Downloaded';
    } else {
      title = 'Downloading Update';
    }

    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              )
            else ...[
              SketchyProgressBar(
                progress: _progress,
                leftLabel: _isAlreadyCached
                    ? 'Cached'
                    : _isDownloading
                        ? 'Downloading'
                        : 'Complete',
                rightLabel: '$percentage%',
              ),
              const SizedBox(height: 8),
              Text(
                _isDownloading
                    ? 'v${widget.version} — download will resume if interrupted'
                    : 'The installer will open automatically.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          if (_errorMessage != null || !_isDownloading)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
        ],
      ),
    );
  }
}
