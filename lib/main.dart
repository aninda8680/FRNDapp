import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import 'theme/app_theme.dart';
import 'routes.dart';
import 'config/dev_config.dart';
import 'services/auth_service.dart';
import 'services/outbox_service.dart';
import 'services/discover_service.dart';
import 'services/update_foreground_task.dart';
import 'services/update_download_service.dart';
import 'services/app_updater.dart';
import 'screens/splash_version_screen.dart';

import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    if (Platform.isAndroid) {
      await FlutterDisplayMode.setHighRefreshRate();
    }
  } catch (_) {
    // Fail silently on unsupported devices
  }

  // Initialise flutter_foreground_task notification channel and options.
  // Must be called before runApp and before startForegroundDownload.
  UpdateForegroundTask.init();

  await Hive.initFlutter();
  await Firebase.initializeApp();
  await AuthService.init();
  OutboxService.start();

  String initialRouteString = AppRoutes.onboarding;

  if (AuthService.token == null || AuthService.token!.isEmpty) {
    initialRouteString = AppRoutes.onboarding;
  } else {
    final cachedProfile = AuthService.userProfile;
    if (cachedProfile != null) {
      AuthService.getProfile(); // background refresh
      if (AuthService.isProfileComplete(cachedProfile)) {
        DiscoverService.prefetchFeed();
        initialRouteString = AppRoutes.main;
      } else {
        initialRouteString = AppRoutes.profileSetup;
      }
    } else {
      final fetchedProfile = await AuthService.getProfile();
      if (fetchedProfile == null) {
        await AuthService.logout();
        initialRouteString = AppRoutes.onboarding;
      } else {
        if (AuthService.isProfileComplete(fetchedProfile)) {
          DiscoverService.prefetchFeed();
          initialRouteString = AppRoutes.main;
        } else {
          initialRouteString = AppRoutes.profileSetup;
        }
      }
    }
  }

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(FrndApp(initialRouteString: initialRouteString));
  FlutterNativeSplash.remove();
}


class FrndApp extends StatefulWidget {
  final String initialRouteString;
  const FrndApp({super.key, required this.initialRouteString});

  @override
  State<FrndApp> createState() => _FrndAppState();
}

/// [AppLifecycleObserver] triggers a deferred APK install when the app returns
/// to the foreground after a background-completed download.
///
/// Scenario:
///   1. User taps "Update" → download starts in foreground service.
///   2. User backgrounds the app.
///   3. Download finishes → state transitions to [DownloadState.done].
///   4. User returns to foreground → this observer fires.
///   5. [BlockingUpdateScreen] is still on the stack (PopScope canPop: false),
///      and its own [didChangeAppLifecycleState] handles the install trigger.
///
/// This observer at the app level is an additional safety net: if
/// [BlockingUpdateScreen] somehow isn't on the stack (e.g. first-launch edge
/// case), we log a debug warning. No double-install risk because
/// [BlockingUpdateScreen._installTriggered] gates the call.
class _FrndAppState extends State<FrndApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final svc = UpdateDownloadService();
      if (svc.state.value == DownloadState.done &&
          svc.currentVersion != null) {
        // BlockingUpdateScreen should already be handling this via its own
        // observer. This is a fallback — attempt install directly if for some
        // reason the screen is not mounted.
        debugPrint(
          '[FrndApp] App resumed with download done — '
          'BlockingUpdateScreen should trigger install.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FRND MVP',
      theme: AppTheme.theme,
      home: SplashVersionScreen(
          targetRoute: DevConfig.initialRouteOverride ?? widget.initialRouteString),
      routes: AppRoutes.routes,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final data = MediaQuery.of(context);
        return MediaQuery(
          data: data.copyWith(
            textScaler:
                data.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.3),
          ),
          child: child!,
        );
      },
    );
  }
}
