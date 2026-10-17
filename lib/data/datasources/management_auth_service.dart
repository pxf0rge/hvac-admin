import 'package:hvac_admin/core/auth/management_sign_in_result.dart';
import 'package:hvac_admin/core/models/management_session.dart';

abstract class ManagementAuthService {
  Future<ManagementSignInResult> signIn({required String email, required String password});
  Future<void> signOut();
  Future<ManagementSession?> restore();
}
