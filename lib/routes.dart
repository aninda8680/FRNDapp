import 'package:flutter/material.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/setup/profile_setup_screen.dart';
import 'screens/main_scaffold.dart';
import 'screens/utilities/notifications_screen.dart';
import 'screens/utilities/search_filters_screen.dart';
import 'screens/utilities/report_block_screen.dart';
import 'screens/utilities/settings_screen.dart';
import 'screens/utilities/help_support_screen.dart';
import 'screens/chats/individual_chat_screen.dart';
import 'screens/profile/edit_profile_screen.dart';

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
  static const String individualChat = '/chats/individual';
  static const String editProfile = '/edit_profile';

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
    individualChat: (context) => const IndividualChatScreen(),
    editProfile: (context) => const EditProfileScreen(),
  };
}
