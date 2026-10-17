/// Application roles for the admin app (`profiles.role`).
enum UserRole {
  owner,
  admin,
  officeStaff,
  technician;

  static UserRole? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    switch (raw.trim().toLowerCase()) {
      case 'owner':
        return UserRole.owner;
      case 'admin':
        return UserRole.admin;
      case 'office_staff':
      case 'officestaff':
      case 'office staff':
        return UserRole.officeStaff;
      case 'technician':
        return UserRole.technician;
      default:
        return null;
    }
  }

  bool get isManagement =>
      this == UserRole.owner || this == UserRole.admin || this == UserRole.officeStaff;

  bool get canViewFinancials => this == UserRole.owner || this == UserRole.admin;
}

extension UserRoleDbX on UserRole {
  String get dbValue => switch (this) {
        UserRole.owner => 'owner',
        UserRole.admin => 'admin',
        UserRole.officeStaff => 'office_staff',
        UserRole.technician => 'technician',
      };

  static UserRole fromDb(String value) => switch (value) {
        'owner' => UserRole.owner,
        'admin' => UserRole.admin,
        'office_staff' => UserRole.officeStaff,
        'technician' => UserRole.technician,
        _ => UserRole.technician,
      };
}

extension UserRoleDisplayX on UserRole {
  String get displayLabel => switch (this) {
        UserRole.owner => 'Owner',
        UserRole.admin => 'Admin',
        UserRole.officeStaff => 'Office Staff',
        UserRole.technician => 'Technician',
      };
}
