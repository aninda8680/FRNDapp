import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../routes.dart';
import '../screens/auth/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/otp_verification_screen.dart';
import '../screens/setup/profile_setup_screen.dart';
import '../screens/setup/profile_created_screen.dart';
import '../screens/main_scaffold.dart';
import '../screens/utilities/notifications_screen.dart';
import '../screens/utilities/search_filters_screen.dart';
import '../screens/utilities/report_block_screen.dart';
import '../screens/utilities/settings_screen.dart';
import '../screens/utilities/help_support_screen.dart';
import '../screens/utilities/privacy_policy_screen.dart';
import '../screens/utilities/terms_of_service_screen.dart';
import '../widgets/maintenance_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/subscription_screen.dart';
import '../screens/profile/profile_updated_screen.dart';
import '../screens/utilities/announcements_screen.dart';
import '../screens/chats/individual_chat_screen.dart';

final initialRouteProvider = Provider<String>((ref) => AppRoutes.onboarding);

final appRouterProvider = Provider<GoRouter>((ref) {
  final initialRoute = ref.watch(initialRouteProvider);
  return GoRouter(
    initialLocation: initialRoute,
    routes: [
      GoRoute(
        path: '/maintenance',
        builder: (context, state) => MaintenanceScreen(
          onRetry: () {
            context.go(initialRoute);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (context, state) => const OtpVerificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileSetup,
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.main,
        builder: (context, state) => const MainScaffold(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.searchFilters,
        builder: (context, state) => const SearchFiltersScreen(),
      ),
      GoRoute(
        path: AppRoutes.reportBlock,
        builder: (context, state) => const ReportBlockScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.helpSupport,
        builder: (context, state) => const HelpSupportScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: AppRoutes.termsOfService,
        builder: (context, state) => const TermsOfServiceScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.subscription,
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: AppRoutes.announcements,
        builder: (context, state) => const AnnouncementsScreen(),
      ),
      GoRoute(
        path: AppRoutes.devProfileUpdated,
        builder: (context, state) => ProfileUpdatedScreen(
          saveFuture: Future.delayed(const Duration(seconds: 3), () => true),
        ),
      ),
      GoRoute(
        path: AppRoutes.devProfileCreated,
        builder: (context, state) => ProfileCreatedScreen(
          saveFuture: Future.delayed(const Duration(seconds: 3), () => true),
        ),
      ),
      // New routes for Deep Linking integration
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final partner = state.extra as Map<String, dynamic>? ?? {};
          return IndividualChatScreen(
            conversationId: id,
            partner: partner,
          );
        },
      ),
    ],
  );
});
