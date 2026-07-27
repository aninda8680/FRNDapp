import 'package:flutter/material.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/setup/profile_setup_screen.dart';
import 'screens/setup/profile_created_screen.dart';
import 'screens/main_scaffold.dart';
import 'screens/utilities/notifications_screen.dart';
import 'screens/utilities/search_filters_screen.dart';
import 'screens/utilities/report_block_screen.dart';
import 'screens/utilities/settings_screen.dart';
import 'screens/utilities/help_support_screen.dart';
import 'screens/utilities/privacy_policy_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/subscription_screen.dart';
import 'screens/profile/profile_updated_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String profileSetup = '/setup';
  static const String main = '/main';
  
  static const String notifications = '/notifications';
  static const String searchFilters = '/search_filters';
  static const String reportBlock = '/report_block';
  static const String settings = '/settings';
  static const String helpSupport = '/help_support';
  static const String privacyPolicy = '/privacy_policy';
  static const String myProfile = '/my_profile';
  static const String editProfile = '/edit_profile';
  static const String subscription = '/subscription';
  
  // Dev Routes
  static const String devProfileUpdated = '/dev_profile_updated';
  static const String devProfileCreated = '/dev_profile_created';

  static Map<String, WidgetBuilder> get routes => {
    splash: (context) => const SplashScreen(),
    onboarding: (context) => const OnboardingScreen(),
    login: (context) => const LoginScreen(),
    otp: (context) => const OtpVerificationScreen(),
    profileSetup: (context) => const ProfileSetupScreen(),
    main: (context) => const MainScaffold(),
    
    notifications: (context) => const NotificationsScreen(),
    searchFilters: (context) => const SearchFiltersScreen(),
    reportBlock: (context) => const ReportBlockScreen(),
    settings: (context) => const SettingsScreen(),
    helpSupport: (context) => const HelpSupportScreen(),
    privacyPolicy: (context) => const PrivacyPolicyScreen(),
    editProfile: (context) => const EditProfileScreen(),
    subscription: (context) => const SubscriptionScreen(),
    
    // Dev Routes
    devProfileUpdated: (context) => ProfileUpdatedScreen(
      saveFuture: Future.delayed(const Duration(seconds: 3), () => true),
    ),
    devProfileCreated: (context) => ProfileCreatedScreen(
      saveFuture: Future.delayed(const Duration(seconds: 3), () => true),
    ),
  };
}
