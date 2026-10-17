import 'package:hvac_admin/core/enums/user_role.dart';

/// Office user row from `profiles` (non-technician).
class OfficeUser {
  const OfficeUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.email,
    this.isActive = true,
  });

  final String id;
  final String firstName;
  final String lastName;
  final UserRole role;
  final String? email;
  final bool isActive;

  String get displayName => '$firstName $lastName'.trim();

  OfficeUser copyWith({
    String? firstName,
    String? lastName,
    UserRole? role,
    String? email,
    bool? isActive,
  }) {
    return OfficeUser(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
    );
  }
}
