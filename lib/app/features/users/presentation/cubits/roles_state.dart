import '../../data/models/permission_model.dart';
import '../../data/models/role_model.dart';

enum RolesStatus { initial, loading, loaded, error }

class RolesState {
  final RolesStatus status;
  final List<RoleModel> roles;
  final List<PermissionModel> permissions;
  final String? errorMessage;
  final bool isSaving;

  const RolesState({
    this.status = RolesStatus.initial,
    this.roles = const [],
    this.permissions = const [],
    this.errorMessage,
    this.isSaving = false,
  });

  /// Groups all available system permissions by their category for intuitive display.
  Map<String, List<PermissionModel>> get groupedPermissions {
    final map = <String, List<PermissionModel>>{};
    for (final perm in permissions) {
      final category = perm.categoryDisplay;
      map.putIfAbsent(category, () => []).add(perm);
    }
    return map;
  }

  /// Finds a role by ID
  RoleModel? getRoleById(int id) {
    try {
      return roles.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Finds a role by name (case-insensitive)
  RoleModel? getRoleByName(String name) {
    final lower = name.trim().toLowerCase();
    try {
      return roles.firstWhere((r) => r.name.trim().toLowerCase() == lower);
    } catch (_) {
      return null;
    }
  }

  /// Resolves the concrete [PermissionModel] objects assigned to a given role
  List<PermissionModel> getPermissionsForRole(RoleModel role) {
    final ids = role.permissionIds.toSet();
    return permissions.where((p) => ids.contains(p.id)).toList();
  }

  RolesState copyWith({
    RolesStatus? status,
    List<RoleModel>? roles,
    List<PermissionModel>? permissions,
    String? errorMessage,
    bool? isSaving,
  }) {
    return RolesState(
      status: status ?? this.status,
      roles: roles ?? this.roles,
      permissions: permissions ?? this.permissions,
      errorMessage: errorMessage,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}
