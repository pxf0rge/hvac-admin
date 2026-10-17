// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:hvac_admin/core/controllers/management_auth_controller.dart';
import 'package:hvac_admin/core/logging/hvac_log.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Keeps the management auth controller aligned with Supabase session lifecycle.
class AuthSessionBridge {
  AuthSessionBridge({
    required SupabaseClient client,
    required ManagementAuthController management,
  })  : _client = client,
        _management = management;

  final SupabaseClient _client;
  final ManagementAuthController _management;

  StreamSubscription<AuthState>? _subscription;
  bool _attached = false;
  bool _handlingRemoteSignOut = false;

  void attach() {
    if (_attached) return;
    _attached = true;
    _subscription = _client.auth.onAuthStateChange.listen(_onAuthState);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _attached = false;
  }

  Future<void> _onAuthState(AuthState state) async {
    switch (state.event) {
      case AuthChangeEvent.signedOut:
        if (_handlingRemoteSignOut) return;
        _handlingRemoteSignOut = true;
        try {
          HvacLog.info('auth.session_expired');
          _management.clearSession();
        } finally {
          _handlingRemoteSignOut = false;
        }
      case AuthChangeEvent.tokenRefreshed:
      case AuthChangeEvent.initialSession:
      case AuthChangeEvent.signedIn:
        if (state.session == null) {
          _management.clearSession();
          return;
        }
        await _management.restore();
      case AuthChangeEvent.userUpdated:
      case AuthChangeEvent.passwordRecovery:
      // ignore: deprecated_member_use
      case AuthChangeEvent.userDeleted:
      case AuthChangeEvent.mfaChallengeVerified:
        break;
    }
  }
}
