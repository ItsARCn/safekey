import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_motion.dart';
import '../features/splash/splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/home/home_screen.dart';
import '../features/add_account/add_account_screen.dart';
import '../features/scanner/scanner_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/export_screen.dart';
import '../features/home/recovery_codes_screen.dart';
import '../features/updater/screens/updates_screen.dart';
import '../database/database.dart';

/// Material 3 Shared-Axis Page Transition
CustomTransitionPage buildPageWithSharedAxisTransition({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
  AxisDirection direction = AxisDirection.up,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: AppMotion.medium3,
    reverseTransitionDuration: AppMotion.medium2,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return AppMotion.sharedAxisTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        child: child,
        direction: direction,
      );
    },
  );
}

/// Material 3 Fade-Through Page Transition
CustomTransitionPage buildPageWithFadeThroughTransition({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: AppMotion.medium3,
    reverseTransitionDuration: AppMotion.medium2,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return AppMotion.fadeThroughTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        child: child,
      );
    },
  );
}

final goRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => buildPageWithFadeThroughTransition(
        context: context,
        state: state,
        child: const SplashScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => buildPageWithFadeThroughTransition(
        context: context,
        state: state,
        child: const OnboardingScreen(),
      ),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => buildPageWithFadeThroughTransition(
        context: context,
        state: state,
        child: const HomeScreen(),
      ),
    ),
    GoRoute(
      path: '/add',
      pageBuilder: (context, state) => buildPageWithSharedAxisTransition(
        context: context,
        state: state,
        child: const AddAccountScreen(),
        direction: AxisDirection.up,
      ),
    ),
    GoRoute(
      path: '/scanner',
      pageBuilder: (context, state) {
        final isGoogleImport = state.uri.queryParameters['mode'] == 'google';
        return buildPageWithSharedAxisTransition(
          context: context,
          state: state,
          child: ScannerScreen(isGoogleImport: isGoogleImport),
          direction: AxisDirection.up,
        );
      },
    ),
    GoRoute(
      path: '/export',
      pageBuilder: (context, state) {
        final accounts = state.extra as List<Account>? ?? [];
        return buildPageWithSharedAxisTransition(
          context: context,
          state: state,
          child: ExportScreen(accounts: accounts),
          direction: AxisDirection.left,
        );
      },
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => buildPageWithSharedAxisTransition(
        context: context,
        state: state,
        child: const SettingsScreen(),
        direction: AxisDirection.left,
      ),
    ),
    GoRoute(
      path: '/recovery',
      pageBuilder: (context, state) {
        final account = state.extra as Account;
        return buildPageWithSharedAxisTransition(
          context: context,
          state: state,
          child: RecoveryCodesScreen(account: account),
          direction: AxisDirection.left,
        );
      },
    ),
    GoRoute(
      path: '/updates',
      pageBuilder: (context, state) => buildPageWithSharedAxisTransition(
        context: context,
        state: state,
        child: const UpdatesScreen(),
        direction: AxisDirection.left,
      ),
    ),
  ],
);

