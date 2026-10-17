import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/app/hvac_admin_app.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/routing/app_router.dart';
import 'package:hvac_admin/core/auth/management_sign_in_result.dart';
import 'package:hvac_admin/core/enums/user_role.dart';
import 'package:hvac_admin/data/datasources/management_auth_service.dart';
import 'package:hvac_admin/data/datasources/mock_management_auth_service.dart';
import 'package:hvac_admin/core/models/management_session.dart';

/// Restore that can hold a session back until the test releases it, emulating
/// network latency during boot (splash must stay up and then auto-continue).
class _HeldRestoreAuthService implements ManagementAuthService {
  final Completer<ManagementSession?> _completer = Completer<ManagementSession?>();
  final Completer<void> _calledCompleter = Completer<void>();

  /// Resolves once the boot restore call reaches the service.
  Future<void> get restoreCalled => _calledCompleter.future;

  /// Releases the pending restore, returning [session].
  void release([ManagementSession? session]) => _completer.complete(session);

  @override
  Future<ManagementSignInResult> signIn({required String email, required String password}) async {
    return ManagementSignInResult.failure(ManagementSignInError.invalidCredentials);
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<ManagementSession?> restore() {
    if (!_calledCompleter.isCompleted) _calledCompleter.complete();
    return _completer.future;
  }
}

ManagementSession _ownerSession() => const ManagementSession(
      userId: 'mgr_owner_1',
      email: 'diana@hvacpro.com',
      firstName: 'Diana',
      lastName: 'Walsh',
      role: UserRole.owner,
    );

void main() {
  group('adminSplashRedirect (pure rules)', () {
    test('holds on splash until boot is ready', () {
      expect(
        adminSplashRedirect(bootReady: false, authenticated: false, pending: null),
        isNull,
      );
      expect(
        adminSplashRedirect(bootReady: false, authenticated: true, pending: null),
        isNull,
      );
    });

    test('continues to dashboard or login after boot', () {
      expect(
        adminSplashRedirect(bootReady: true, authenticated: false, pending: null),
        '/login',
      );
      expect(
        adminSplashRedirect(bootReady: true, authenticated: true, pending: null),
        AdminModule.dashboard.path,
      );
    });

    test('re-dispatches deep link held during boot', () {
      expect(
        adminSplashRedirect(
          bootReady: true,
          authenticated: true,
          pending: Uri.parse('/invoices'),
        ),
        '/invoices',
      );
    });
  });

  testWidgets('splash is the first screen and then continues to login', (WidgetTester tester) async {
    await tester.pumpWidget(const HvacAdminApp());
    // Splash visible immediately (before boot completes).
    expect(find.byKey(const Key('splash-screen')), findsOneWidget);

    await tester.pumpAndSettle();

    // Boot finished without a session: login, without a lingering splash.
    expect(find.text('Office sign in'), findsOneWidget);
    expect(find.byKey(const Key('splash-screen')), findsNothing);
  });

  testWidgets('restored session lands on dashboard, never showing login', (WidgetTester tester) async {
    final service = _HeldRestoreAuthService();
    await tester.pumpWidget(HvacAdminApp(managementAuthOverride: service));

    // Boot restore is in flight: splash still showing, no login flash.
    await service.restoreCalled;
    await tester.pump();
    expect(find.byKey(const Key('splash-screen')), findsOneWidget);
    expect(find.text('Office sign in'), findsNothing);

    // Restore finishes with a session → splash must auto-continue to home.
    service.release(_ownerSession());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard')), findsOneWidget);
    expect(find.text('Office sign in'), findsNothing);
    expect(find.byKey(const Key('splash-screen')), findsNothing);
  });

  testWidgets('deep link during boot is held and opened after sign-in gate', (WidgetTester tester) async {
    await tester.pumpWidget(const HvacAdminApp());
    // Arrive on splash even when a deep link was requested mid-boot.
    GoRouter.of(tester.element(find.byKey(const Key('splash-screen')))).go('/jobs');
    await tester.pump();
    expect(find.byKey(const Key('splash-screen')), findsOneWidget);

    await tester.pumpAndSettle();
    // Unauthenticated → login; after sign-in the app opens the held path.
    expect(find.text('Office sign in'), findsOneWidget);
    await _signIn(tester, 'diana@hvacpro.com', 'OfficeLead!');
    expect(find.textContaining('JOB-'), findsWidgets);
  });
}

Future<void> _signIn(WidgetTester tester, String email, String password) async {
  await tester.enterText(find.byType(TextFormField).at(0), email);
  await tester.enterText(find.byType(TextFormField).at(1), password);
  await tester.tap(find.text('Sign in'));
  await tester.pumpAndSettle();
}
