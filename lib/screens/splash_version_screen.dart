import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/version_service.dart';
import '../widgets/force_update_dialog.dart';
import '../widgets/optional_update_dialog.dart';
import '../widgets/maintenance_screen.dart';

/// A minimal splash screen that runs the version check before proceeding to
/// [targetRoute].
///
/// Navigation contract:
/// All three exit paths use [pushReplacementNamed] / [pushAndRemoveUntil] so
/// this screen is fully removed from the navigator stack and is never reachable
/// via the back button from subsequent screens.
///
/// Back-button bug fix:
/// The previous implementation left SplashVersionScreen alive under dialogs
/// and under the maintenance screen. This version:
///   • Maintenance → pushAndRemoveUntil(MaintenanceScreen) — fully replaces
///     the splash in the stack.
///   • Force update → dialog closes itself; BlockingUpdateScreen is pushed by
///     ForceUpdateDialog. _navigateToHome() is NOT called in the force-update
///     path (the update resolves it instead).
///   • Optional update → BlockingUpdateScreen is pushed by OptionalUpdateDialog
///     when user taps Update; "Later" triggers _navigateToHome() in .then().
///
/// Re-fire guard:
/// [_hasChecked] ensures checkVersion() fires exactly once per widget lifetime,
/// even if the widget is rebuilt (e.g. from an orientation change or hot-reload).
class SplashVersionScreen extends StatefulWidget {
  final String targetRoute;

  const SplashVersionScreen({super.key, required this.targetRoute});

  // ── Wi-Fi check ───────────────────────────────────────────────────────────

  /// Checks connectivity and warns the user if they are on cellular data
  /// before a large download starts. Called by dialogs indirectly — exposed
  /// as a static utility so ForceUpdateDialog / OptionalUpdateDialog can use it.
  static Future<bool> confirmCellularDownload(BuildContext context) async {
    final result = await Connectivity().checkConnectivity();
    final isOnCellular = result.contains(ConnectivityResult.mobile) &&
        !result.contains(ConnectivityResult.wifi);

    if (!isOnCellular) return true; // Wi-Fi or Ethernet — proceed immediately

    if (!context.mounted) return false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mobile Data Warning'),
        content: const Text(
          'You are on mobile data. Downloading the update may use '
          'significant data (several MB). Continue on mobile data?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Wait for Wi-Fi'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  @override
  State<SplashVersionScreen> createState() => _SplashVersionScreenState();
}

class _SplashVersionScreenState extends State<SplashVersionScreen> {
  final VersionService _versionService = VersionService();

  bool _isChecking = true;
  bool _hasChecked = false; // Guard against re-fires on rebuild

  @override
  void initState() {
    super.initState();
    _runVersionCheck();
  }

  Future<void> _runVersionCheck() async {
    // Idempotency guard — do not re-fire if already in progress or done.
    if (_hasChecked) return;
    _hasChecked = true;

    if (mounted) setState(() => _isChecking = true);

    final result = await _versionService.checkVersion();

    if (!mounted) return;

    switch (result.status) {
      case UpdateStatus.maintenance:
        // Replace splash with maintenance screen — fully removed from stack.
        // [MaintenanceScreen.onRetry] resets [_hasChecked] so the user can
        // re-trigger the check after the outage ends.
        _navigateToMaintenance();

      case UpdateStatus.forceUpdate:
        setState(() => _isChecking = false);
        _showForceUpdateDialog(
          result.appVersion?.playStoreUrl ?? '',
          result.appVersion?.latestVersion ?? '',
          result.appVersion?.sha256,
        );
        // Do NOT call _navigateToHome() here. ForceUpdateDialog → BlockingUpdateScreen
        // takes over. SplashVersionScreen is removed from the stack by
        // BlockingUpdateScreen's Navigator.push (rootNavigator: true) which
        // sits above it. We leave the splash blank underneath; the user will
        // never see it because PopScope(canPop:false) blocks back navigation.

      case UpdateStatus.optionalUpdate:
        // The .then() callback fires when the dialog is dismissed for ANY
        // reason (user tapped "Later" OR tapped "Update" and popped the dialog
        // before BlockingUpdateScreen was pushed). The UpdateDownloadService
        // state check below distinguishes the two cases.
        _showOptionalUpdateDialogAndProceed(
          result.appVersion?.latestVersion ?? '',
          result.appVersion?.playStoreUrl ?? '',
          result.appVersion?.sha256,
        );

      case UpdateStatus.upToDate:
      case UpdateStatus.checkFailed:
        _navigateToHome();
    }
  }

  // ── Navigation helpers ────────────────────────────────────────────────────

  /// Replaces the splash — and every other route — with [MaintenanceScreen].
  void _navigateToMaintenance() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => MaintenanceScreen(
          onRetry: () {
            // Pop the maintenance screen and re-run the version check from a
            // fresh SplashVersionScreen — placed back at the stack root.
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(
                builder: (_) =>
                    SplashVersionScreen(targetRoute: widget.targetRoute),
              ),
              (route) => false,
            );
          },
        ),
      ),
      (route) => false, // Remove every previous route including splash
    );
  }

  void _showForceUpdateDialog(
      String playStoreUrl, String latestVersion, String? sha256) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ForceUpdateDialog(
        playStoreUrl: playStoreUrl,
        latestVersion: latestVersion,
        sha256: sha256,
      ),
    );
  }

  void _showOptionalUpdateDialogAndProceed(
    String latestVersion,
    String playStoreUrl,
    String? sha256,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => OptionalUpdateDialog(
        latestVersion: latestVersion,
        playStoreUrl: playStoreUrl,
        sha256: sha256,
      ),
    ).then((_) {
      // Dialog was dismissed. Navigate home only if the user chose "Later"
      // (i.e. the download is NOT in blocking/updating mode).
      // If the user tapped "Update", BlockingUpdateScreen was already pushed;
      // calling _navigateToHome() here would incorrectly remove it.
      if (mounted) {
        _navigateToHome();
      }
    });
  }

  /// Navigates to [targetRoute], replacing this screen so it is not reachable
  /// via back navigation.
  void _navigateToHome() {
    Navigator.of(context).pushReplacementNamed(widget.targetRoute);
  }



  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isChecking
            ? const CircularProgressIndicator()
            : const SizedBox.shrink(),
      ),
    );
  }
}
