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
import 'services/play_billing_service.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import 'services/fcm_token_manager.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

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

  // Initialise Google Play Billing and begin listening to the purchase stream.
  await PlayBillingService.instance.init();

  String initialRouteString = AppRoutes.onboarding;

  if (AuthService.token == null || AuthService.token!.isEmpty) {
    initialRouteString = AppRoutes.onboarding;
  } else {
    final cachedProfile = AuthService.userProfile;
    if (cachedProfile != null) {
      AuthService.getProfile(); // background refresh
      if (!AuthService.isEmailVerified(cachedProfile)) {
        initialRouteString = AppRoutes.otp;
      } else if (AuthService.isProfileComplete(cachedProfile)) {
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
        if (!AuthService.isEmailVerified(fetchedProfile)) {
          initialRouteString = AppRoutes.otp;
        } else if (AuthService.isProfileComplete(fetchedProfile)) {
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

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    ProviderScope(
      overrides: [
        initialRouteProvider.overrideWithValue(initialRouteString),
      ],
      child: const FrndApp(),
    ),
  );
  FlutterNativeSplash.remove();
}


class FrndApp extends ConsumerStatefulWidget {
  const FrndApp({super.key});

  @override
  ConsumerState<FrndApp> createState() => _FrndAppState();
}

class _FrndAppState extends ConsumerState<FrndApp> {
  @override
  void initState() {
    super.initState();
    
    // Setup FCM
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    // Wait for initial render if needed, or initialize directly
    await FcmTokenManager.initNotifications(ref);
    await _setupInteractedMessage();
  }

  Future<void> _setupInteractedMessage() async {
    // 1. Terminated (Cold Start)
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleDeepLink(initialMessage.data);
    }

    // 2. Background (App in memory, user taps notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleDeepLink(message.data);
    });
  }

  void _handleDeepLink(Map<String, dynamic> data) {
    final type = data['type'];
    final router = ref.read(appRouterProvider);
    if (type == 'chat') {
      final chatId = data['chatId'];
      if (chatId != null) {
        router.go('/chat/$chatId');
      }
    } else if (type == 'profile') {
      final userId = data['userId'];
      if (userId != null) {
        // Assuming there is a /profile route in the future
        // router.go('/profile/$userId');
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'FRND MVP',
      theme: AppTheme.theme,
      routerConfig: router,
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
