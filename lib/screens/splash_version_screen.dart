import 'package:flutter/material.dart';
import '../services/version_service.dart';
import '../widgets/force_update_dialog.dart';
import '../widgets/optional_update_dialog.dart';
import '../widgets/maintenance_screen.dart';

/// A minimal splash screen that runs the version check before proceeding to the specified target route.
class SplashVersionScreen extends StatefulWidget {
  final String targetRoute;

  const SplashVersionScreen({super.key, required this.targetRoute});

  @override
  State<SplashVersionScreen> createState() => _SplashVersionScreenState();
}

class _SplashVersionScreenState extends State<SplashVersionScreen> {
  final VersionService _versionService = VersionService();
  bool _isChecking = true;
  bool _isMaintenance = false;

  @override
  void initState() {
    super.initState();
    _runVersionCheck();
  }

  Future<void> _runVersionCheck() async {
    setState(() {
      _isChecking = true;
      _isMaintenance = false;
    });

    final result = await _versionService.checkVersion();

    if (!mounted) return;

    switch (result.status) {
      case UpdateStatus.maintenance:
        setState(() {
          _isChecking = false;
          _isMaintenance = true;
        });
        break;

      case UpdateStatus.forceUpdate:
        setState(() => _isChecking = false);
        _showForceUpdateDialog(
          result.appVersion?.playStoreUrl ?? '',
          result.appVersion?.latestVersion ?? '',
        );
        break;

      case UpdateStatus.optionalUpdate:
        _showOptionalUpdateDialogAndProceed(
          result.appVersion?.latestVersion ?? '',
          result.appVersion?.playStoreUrl ?? '',
        );
        break;

      case UpdateStatus.upToDate:
      case UpdateStatus.checkFailed:
        _navigateToHome();
        break;
    }
  }

  void _showForceUpdateDialog(String playStoreUrl, String latestVersion) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ForceUpdateDialog(
        playStoreUrl: playStoreUrl,
        latestVersion: latestVersion,
      ),
    );
  }

  void _showOptionalUpdateDialogAndProceed(String latestVersion, String playStoreUrl) {
    showDialog(
      context: context,
      builder: (_) => OptionalUpdateDialog(
        latestVersion: latestVersion,
        playStoreUrl: playStoreUrl,
      ),
    ).then((_) {
      if (mounted) {
        _navigateToHome();
      }
    });
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacementNamed(widget.targetRoute);
  }

  @override
  Widget build(BuildContext context) {
    if (_isMaintenance) {
      return MaintenanceScreen(onRetry: _runVersionCheck);
    }

    return Scaffold(
      body: Center(
        child: _isChecking
            ? const CircularProgressIndicator()
            : const SizedBox.shrink(),
      ),
    );
  }
}
