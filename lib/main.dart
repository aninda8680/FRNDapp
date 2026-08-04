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
    systemNavigationBarColor: Colors.black, // Dark to match bottom nav
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(FrndApp(initialRouteString: initialRouteString));
  FlutterNativeSplash.remove();
}


class FrndApp extends StatelessWidget {
  final String initialRouteString;
  const FrndApp({super.key, required this.initialRouteString});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FRND MVP',
      theme: AppTheme.theme,
      home: SplashVersionScreen(targetRoute: DevConfig.initialRouteOverride ?? initialRouteString),
      routes: AppRoutes.routes,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final data = MediaQuery.of(context);
        return MediaQuery(
          data: data.copyWith(
            textScaler: data.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.3),
          ),
          child: child!,
        );
      },
    );
  }
}

