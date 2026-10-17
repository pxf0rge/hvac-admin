import 'package:hvac_admin/core/models/management_session.dart';

enum ManagementSignInError {
  invalidCredentials,
  technicianNotAllowed,
  profileNotFound,
  accountDisabled,
}

class ManagementSignInResult {
  const ManagementSignInResult._({this.session, this.error});

  final ManagementSession? session;
  final ManagementSignInError? error;

  bool get isSuccess => session != null;

  factory ManagementSignInResult.success(ManagementSession session) =>
      ManagementSignInResult._(session: session);

  factory ManagementSignInResult.failure(ManagementSignInError error) =>
      ManagementSignInResult._(error: error);
}
