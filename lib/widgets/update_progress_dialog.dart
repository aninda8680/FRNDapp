import 'package:flutter/material.dart';
import '../services/update_download_service.dart';
import 'sketchy_progress_bar.dart';

/// A non-blocking progress UI that listens to [UpdateDownloadService].
/// Dismissing this dialog does NOT cancel the download — it continues in the
/// background. The user can re-open the banner at any time.
class UpdateProgressDialog extends StatefulWidget {
  /// Only needed when launched from ForceUpdateDialog (to start the download).
  final String? apkUrl;
  final String? version;

  const UpdateProgressDialog({super.key, this.apkUrl, this.version});

  @override
  State<UpdateProgressDialog> createState() => _UpdateProgressDialogState();
}

class _UpdateProgressDialogState extends State<UpdateProgressDialog> {
  final _service = UpdateDownloadService();

  @override
  void initState() {
    super.initState();
    // If called from a context that needs to start the download (e.g. force update)
    if (widget.apkUrl != null && widget.version != null) {
      _service.start(url: widget.apkUrl!, version: widget.version!);
    }
    _service.progress.addListener(_rebuild);
    _service.state.addListener(_rebuild);
    _service.state.addListener(_autoClose);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _autoClose() {
    // Auto-close once done so the installer takes focus
    if (_service.state.value == DownloadState.done && mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  void dispose() {
    // DO NOT cancel the download — the service lives on.
    _service.progress.removeListener(_rebuild);
    _service.state.removeListener(_rebuild);
    _service.state.removeListener(_autoClose);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _service.state.value;
    final progress = _service.progress.value;
    final error = _service.errorMessage.value;
    final int percentage = (progress * 100).toInt();

    String title;
    if (error != null) {
      title = 'Download Failed';
    } else if (state == DownloadState.done) {
      title = 'Ready to Install';
    } else {
      title = 'Downloading Update';
    }

    return PopScope(
      canPop: true, // Allow dismissing — download continues
      child: AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (error != null)
              Text(error, style: const TextStyle(color: Colors.red))
            else ...[
              SketchyProgressBar(
                progress: progress,
                leftLabel: state == DownloadState.done
                    ? 'Complete'
                    : 'Downloading',
                rightLabel: '$percentage%',
              ),
              const SizedBox(height: 8),
              Text(
                state == DownloadState.done
                    ? 'Opening installer…'
                    : 'Download continues even if you close this.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          if (error != null)
            TextButton(
              onPressed: () {
                if (widget.apkUrl != null && widget.version != null) {
                  _service.retry(
                      url: widget.apkUrl!, version: widget.version!);
                }
              },
              child: const Text('Retry'),
            ),
          // Always show a dismiss option so user can go back to the app
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to App'),
          ),
        ],
      ),
    );
  }
}
