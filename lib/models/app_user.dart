/// User roles: Admin can do everything, Manager can manage stock/POs,
/// Picker can only view and pick tasks.
enum UserRole { admin, manager, picker }

extension UserRoleX on UserRole {
  String get label => switch (this) {
        UserRole.admin => 'Admin',
        UserRole.manager => 'Manager',
        UserRole.picker => 'Picker',
      };

  String get key => name;

  static UserRole parse(String? s) => UserRole.values
      .firstWhere((e) => e.name == s, orElse: () => UserRole.picker);
}

class Permissions {
  Permissions._();
  static bool canEditProduct(UserRole role) =>
      role == UserRole.admin || role == UserRole.manager;
  static bool canDeleteProduct(UserRole role) => role == UserRole.admin;
  static bool canManagePO(UserRole role) =>
      role == UserRole.admin || role == UserRole.manager;
  static bool canReceiveStock(UserRole role) =>
      role == UserRole.admin || role == UserRole.manager;
  static bool canRunCycleCount(UserRole role) =>
      role == UserRole.admin || role == UserRole.manager;
  static bool canApproveCycleCount(UserRole role) => role == UserRole.admin;
  static bool canManageUsers(UserRole role) => role == UserRole.admin;
  static bool canViewKPIs(UserRole role) =>
      role == UserRole.admin || role == UserRole.manager;
}

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.warehouseId = '',
  });

  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final String warehouseId;

  AppUser copyWith({UserRole? role}) => AppUser(
        uid: uid,
        email: email,
        displayName: displayName,
        role: role ?? this.role,
        warehouseId: warehouseId,
      );

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) => AppUser(
        uid: uid,
        email: (m['email'] as String?) ?? '',
        displayName: (m['displayName'] as String?) ?? 'User',
        role: UserRoleX.parse(m['role'] as String?),
        warehouseId: (m['warehouseId'] as String?) ?? '',
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'role': role.key,
        'warehouseId': warehouseId,
      };
}
