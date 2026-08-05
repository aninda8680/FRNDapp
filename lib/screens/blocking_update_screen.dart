import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/update_download_service.dart';
import '../services/app_updater.dart';
import '../theme/app_colors.dart';
import '../widgets/sketchy_progress_bar.dart';

/// A full-screen, non-dismissible update screen shown when the user has
/// committed to an update (either forced or optional-accepted).
///
/// Blocking guarantees:
/// • [PopScope(canPop: false)] prevents the Android back button and edge-swipe.
/// • Pushed via [Navigator.of(context, rootNavigator: true).push()] so it sits
///   above every in-app route and cannot be bypassed by nested navigators.
/// • No "Back to App" or "Dismiss" affordance — only Retry (on failure).
///
/// Install timing:
/// The install intent fires only when [AppLifecycleState.resumed] is active,
/// ensuring we are in an Activity context (required for OpenFilex to work
/// reliably without FLAG_ACTIVITY_NEW_TASK on all OEMs).
class BlockingUpdateScreen extends StatefulWidget {
  final String apkUrl;
  final String version;
  final String? sha256;

  const BlockingUpdateScreen({
    super.key,
    required this.apkUrl,
    required this.version,
    this.sha256,
  });

  /// Helper to push this screen onto the root navigator so it covers
  /// everything — safe to call from inside a dialog or nested navigator.
  static Future<void> show({
    required BuildContext context,
    required String apkUrl,
    required String version,
    String? sha256,
  }) {
    return Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BlockingUpdateScreen(
          apkUrl: apkUrl,
          version: version,
          sha256: sha256,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  State<BlockingUpdateScreen> createState() => _BlockingUpdateScreenState();
}

class _BlockingUpdateScreenState extends State<BlockingUpdateScreen>
    with WidgetsBindingObserver {
  final _svc = UpdateDownloadService();

  /// Tracks whether we have already triggered the install intent so we don't
  /// call it twice on repeated [AppLifecycleState.resumed] events.
  bool _installTriggered = false;

  /// Error from the install step (distinct from the download error stored in svc).
  String? _installError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _svc.state.addListener(_onStateChanged);

    // If the download is already done when this screen appears (e.g. the
    // foreground service finished while a previous screen was visible), trigger
    // install immediately.
    if (_svc.state.value == DownloadState.done) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _triggerInstall());
    }
  }

  @override
  void dispose() {
    _svc.state.removeListener(_onStateChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ── Lifecycle observer ────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If the download completed while the app was backgrounded, trigger the
    // install intent as soon as the user returns to the foreground.
    if (state == AppLifecycleState.resumed &&
        _svc.state.value == DownloadState.done &&
        !_installTriggered) {
      _triggerInstall();
    }
  }

  // ── State listener ────────────────────────────────────────────────────────

  void _onStateChanged() {
    if (!mounted) return;
    setState(() {});

    if (_svc.state.value == DownloadState.done && !_installTriggered) {
      _triggerInstall();
    }
  }

  // ── Install ───────────────────────────────────────────────────────────────

  Future<void> _triggerInstall() async {
    if (_installTriggered) return;
    _installTriggered = true;

    setState(() => _installError = null);

    try {
      // installApk() is called here — from the Flutter widget/Activity context
      // — so FLAG_ACTIVITY_NEW_TASK is NOT needed. The system installer sheet
      // appears immediately on all OEMs.
      await AppUpdater().installApk(version: widget.version);
    } catch (e) {
      _installTriggered = false; // Allow retry
      if (mounted) {
        setState(() {
          _installError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  // ── Retry ─────────────────────────────────────────────────────────────────

  void _retry() {
    _installError = null;
    _installTriggered = false;
    _svc.retry(
      url: widget.apkUrl,
      version: widget.version,
      sha256: widget.sha256,
    );
    setState(() {});
  }

  // ── Formatting helpers ────────────────────────────────────────────────────

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 MB';
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Back button and edge-swipe are disabled.
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: AppColors.cream,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: ValueListenableBuilder<DownloadState>(
                valueListenable: _svc.state,
                builder: (context, state, _) {
                  return _buildBody(state);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(DownloadState state) {
    // Install step error takes visual priority over download done state
    if (_installError != null) {
      return _buildError(_installError!);
    }
    if (state == DownloadState.failed) {
      return _buildError(_svc.errorMessage.value ?? 'Download failed.');
    }
    if (state == DownloadState.done) {
      return _buildInstalling();
    }
    return _buildDownloading(state);
  }

  Widget _buildDownloading(DownloadState state) {
    return ValueListenableBuilder<double>(
      valueListenable: _svc.progress,
      builder: (context, progress, _) {
        final pct = (progress * 100).toInt();
        final downloaded = _svc.downloadedBytes.value;
        final total = _svc.totalBytes.value;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon
            const Icon(
              Icons.system_update_alt_rounded,
              size: 72,
              color: AppColors.textColor2,
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              'Updating FrndBuzz',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.inkBlack,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              'v${widget.version}',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceMono(
                fontSize: 13,
                color: AppColors.textColor2,
              ),
            ),
            const SizedBox(height: 48),

            // Progress bar
            SketchyProgressBar(
              progress: progress,
              leftLabel: total > 0
                  ? '${_formatBytes(downloaded)} / ${_formatBytes(total)}'
                  : 'Downloading…',
              rightLabel: '$pct%',
            ),
            const SizedBox(height: 32),

            // Sub-text
            Text(
              'Please keep the app open.\nThe update will install automatically when ready.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppColors.inkBlack.withOpacity(0.6),
                height: 1.5,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInstalling() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.download_done_rounded,
          size: 72,
          color: AppColors.textColor2,
        ),
        const SizedBox(height: 32),
        Text(
          'Ready to Install',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.inkBlack,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Opening the installer…',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: AppColors.inkBlack.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 24),
        const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _buildError(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          size: 72,
          color: Colors.red,
        ),
        const SizedBox(height: 32),
        Text(
          'Update Failed',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.inkBlack,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.red.shade800,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _retry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.textColor2,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'The app requires this update to continue.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: AppColors.inkBlack.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}
