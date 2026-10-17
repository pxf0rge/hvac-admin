import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/boot/app_boot_controller.dart';
import 'package:hvac_admin/core/controllers/management_auth_controller.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/routing/admin_route_guard.dart';
import 'package:hvac_admin/core/routing/admin_routes.dart';
import 'package:hvac_admin/features/auth/login_screen.dart';
import 'package:hvac_admin/features/portal/payment_result_page.dart';
import 'package:hvac_admin/features/portal/portal_view_page.dart';
import 'package:hvac_admin/features/shared/admin_shell.dart';
import 'package:hvac_admin/features/shared/splash_screen.dart';

bool isPublicPortalPath(String path) {
  return path.startsWith('/e/') ||
      path.startsWith('/i/') ||
      path.startsWith('/d/') ||
      path == '/payments/success' ||
      path == '/payments/cancel' ||
      path.startsWith('/payments/mock-checkout/');
}

/// Where the splash should send the user once boot finished.
String? adminSplashRedirect({
  required bool bootReady,
  required bool authenticated,
  required Uri? pending,
}) {
  if (!bootReady) return null;
  // Re-dispatch a held deep link; the guard rules re-apply to it.
  if (authenticated && pending != null) return pending.toString();
  return authenticated ? AdminModule.dashboard.path : '/login';
}

/// Standard auth/permission gate applied outside the splash.
String? adminAuthRedirect({
  required bool authenticated,
  required String path,
  required bool Function(String path) canOpenPath,
}) {
  final loggingIn = path == '/login';
  if (!authenticated && !loggingIn) return '/login';
  if (authenticated && loggingIn) return AdminModule.dashboard.path;
  if (path == '/') return authenticated ? AdminModule.dashboard.path : '/login';

  if (authenticated && path == '/access-denied') return null;

  if (authenticated && !canOpenPath(path)) {
    return AdminModule.dashboard.path;
  }

  return null;
}

GoRouter createAppRouter(ManagementAuthController auth, AppBootController boot) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: Listenable.merge([auth, boot]),
    redirect: (context, state) {
      final path = state.uri.path;

      // Customer magic links — no office login required, no boot gate.
      if (isPublicPortalPath(path)) return null;

      // Splash stays until boot (auth restore + initial loads) finishes, then
      // sends the user straight to the dashboard or login — no login flash.
      if (path == '/splash') {
        return adminSplashRedirect(
          bootReady: boot.isReady,
          authenticated: auth.isAuthenticated,
          pending: boot.pendingLocation,
        );
      }

      // Remember deep links that must survive login (held during boot or
      // bounced off the auth gate); released after sign-in or on restore.
      boot.hold(state.uri, authenticated: auth.isAuthenticated);
      if (!boot.isReady) return '/splash';

      // Sign-in completion re-dispatches a deep link held during boot.
      if (auth.isAuthenticated && path == '/login') {
        final pending = boot.consumePending();
        if (pending != null) return pending.toString();
      }

      return adminAuthRedirect(
        authenticated: auth.isAuthenticated,
        path: path,
        canOpenPath: (p) => canOpenAdminPath(auth, p),
      );
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/e/:token',
        builder: (_, state) => PortalViewPage(
          token: state.pathParameters['token'] ?? '',
          expectedType: 'estimate',
        ),
      ),
      GoRoute(
        path: '/i/:token',
        builder: (_, state) => PortalViewPage(
          token: state.pathParameters['token'] ?? '',
          expectedType: 'invoice',
        ),
      ),
      GoRoute(
        path: '/d/:token',
        builder: (_, state) => PortalViewPage(
          token: state.pathParameters['token'] ?? '',
          expectedType: 'document',
        ),
      ),
      GoRoute(
        path: '/payments/success',
        builder: (_, _) => const PaymentResultPage(success: true),
      ),
      GoRoute(
        path: '/payments/cancel',
        builder: (_, _) => const PaymentResultPage(success: false),
      ),
      GoRoute(
        path: '/payments/mock-checkout/:id',
        builder: (_, state) => PaymentResultPage(
          key: Key('mock-checkout-${state.pathParameters['id'] ?? ''}'),
          success: false,
          title: 'Test checkout',
          message:
              'PAYMENTS_TEST_MODE mock session ${state.pathParameters['id'] ?? ''}. '
              'Configure Stripe keys for real Checkout. No charge was made.',
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: buildAdminShellRoutes(),
      ),
    ],
  );
}
