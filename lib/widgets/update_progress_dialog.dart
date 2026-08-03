import 'package:flutter/material.dart';
import '../services/app_updater.dart';
import 'sketchy_progress_bar.dart';

class UpdateProgressDialog extends StatefulWidget {
  final String apkUrl;

  const UpdateProgressDialog({super.key, required this.apkUrl});

  @override
  State<UpdateProgressDialog> createState() => _UpdateProgressDialogState();
}

class _UpdateProgressDialogState extends State<UpdateProgressDialog> {
  double _progress = 0.0;
  bool _isDownloading = true;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      await AppUpdater().downloadAndInstall(
        widget.apkUrl,
        (received, total) {
          if (total != -1 && mounted) {
            setState(() {
              _progress = received / total;
            });
          }
        },
      );
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int percentage = (_progress * 100).toInt();
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('Downloading Update'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SketchyProgressBar(
              progress: _progress,
              leftLabel: 'Downloading',
              rightLabel: '$percentage%',
            ),
          ],
        ),
      ),
    );
  }
}
