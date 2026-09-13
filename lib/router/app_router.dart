import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../routes.dart';
import '../services/auth_service.dart';
import '../screens/auth/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/auth_screen.dart';
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
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isAuth = AuthService.token != null;

      // Routes anyone (including logged-out users) may visit.
      const public = [
        AppRoutes.onboarding,
        AppRoutes.login,
        AppRoutes.signup,
        AppRoutes.privacyPolicy,
        AppRoutes.termsOfService,
        AppRoutes.helpSupport,
        '/maintenance',
      ];

      // Anything else requires a session — send deep links to onboarding.
      if (!isAuth && !public.contains(location)) {
        return AppRoutes.onboarding;
      }
      if (!isAuth) return null;

      // Profile not loaded yet (e.g. right after signup, before the first
      // getProfile call). Screen-level logic resolves routing in that case.
      final profile = AuthService.userProfile;
      if (profile == null) return null;

      final verified = AuthService.isEmailVerified(profile);
      final complete = AuthService.isProfileComplete(profile);

      if (!verified) {
        // Unverified users may only be on OTP (or public pages).
        if (location == AppRoutes.otp || public.contains(location)) {
          return null;
        }
        return AppRoutes.otp;
      }

      if (location == AppRoutes.onboarding ||
          location == AppRoutes.login ||
          location == AppRoutes.signup ||
          location == AppRoutes.otp) {
        return complete ? AppRoutes.main : AppRoutes.profileSetup;
      }
      return null;
    },
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
        pageBuilder: (context, state) => _buildAestheticTransition(
          context: context,
          state: state,
          child: const AuthScreen(startOnSignUp: false),
        ),
      ),
      GoRoute(
        path: AppRoutes.signup,
        pageBuilder: (context, state) => _buildAestheticTransition(
          context: context,
          state: state,
          child: const AuthScreen(startOnSignUp: true),
        ),
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

CustomTransitionPage<void> _buildAestheticTransition({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 700),
    reverseTransitionDuration: const Duration(milliseconds: 700),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // A smooth and elegant curve
      const curve = Curves.fastLinearToSlowEaseIn;

      final slideTween = Tween(begin: const Offset(0.0, 0.1), end: Offset.zero)
          .chain(CurveTween(curve: curve));
      final fadeTween = Tween(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: curve));
      final scaleTween = Tween(begin: 0.96, end: 1.0)
          .chain(CurveTween(curve: curve));

      return FadeTransition(
        opacity: animation.drive(fadeTween),
        child: ScaleTransition(
          scale: animation.drive(scaleTween),
          child: SlideTransition(
            position: animation.drive(slideTween),
            child: child,
          ),
        ),
      );
    },
  );
}

CustomTransitionPage<void> _buildAuthTransition({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 600),
    reverseTransitionDuration: const Duration(milliseconds: 600),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slideIn = Tween<Offset>(
        begin: const Offset(0.2, 0.0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.fastLinearToSlowEaseIn,
        ),
      );

      final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
        ),
      );

      return FadeTransition(
        opacity: fadeIn,
        child: SlideTransition(
          position: slideIn,
          child: child,
        ),
      );
    },
  );
}
