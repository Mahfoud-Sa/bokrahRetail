import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/roles_service.dart';
import 'roles_state.dart';

class RolesCubit extends Cubit<RolesState> {
  final RolesService _rolesService;

  RolesCubit({required RolesService rolesService})
      : _rolesService = rolesService,
        super(const RolesState());

  /// Loads both roles and system permissions simultaneously.
  Future<void> loadRolesAndPermissions() async {
    emit(state.copyWith(status: RolesStatus.loading));
    try {
      final results = await Future.wait([
        _rolesService.getRoles(),
        _rolesService.getPermissions(),
      ]);

      final roles = results[0] as List<dynamic>;
      final permissions = results[1] as List<dynamic>;

      emit(state.copyWith(
        status: RolesStatus.loaded,
        roles: roles.cast(),
        permissions: permissions.cast(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: RolesStatus.error,
        errorMessage: 'فشل في تحميل بيانات الأدوار والصلاحيات: $e',
      ));
    }
  }

  /// Creates a new custom role with assigned permissions.
  Future<bool> createRole({
    required String name,
    List<int> permissionIds = const [],
  }) async {
    emit(state.copyWith(isSaving: true));
    try {
      final created = await _rolesService.createRole(
        name,
        permissionIds: permissionIds,
      );

      final updatedRoles = List.of(state.roles)
        ..removeWhere((r) => r.id == created.id)
        ..add(created);

      emit(state.copyWith(
        roles: updatedRoles,
        isSaving: false,
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        errorMessage: 'فشل في إنشاء الدور: $e',
      ));
      return false;
    }
  }

  /// Updates an existing role's name and/or permissions.
  Future<bool> updateRole({
    required int id,
    required String name,
    List<int>? permissionIds,
  }) async {
    emit(state.copyWith(isSaving: true));
    try {
      final updated = await _rolesService.updateRole(
        id,
        name,
        permissionIds: permissionIds,
      );

      final updatedRoles = List.of(state.roles);
      final index = updatedRoles.indexWhere((r) => r.id == id);
      if (index != -1) {
        updatedRoles[index] = updated;
      } else {
        updatedRoles.add(updated);
      }

      emit(state.copyWith(
        roles: updatedRoles,
        isSaving: false,
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        errorMessage: 'فشل في تعديل الدور: $e',
      ));
      return false;
    }
  }

  /// Deletes a custom role.
  Future<bool> deleteRole(int id) async {
    emit(state.copyWith(isSaving: true));
    try {
      final success = await _rolesService.deleteRole(id);
      if (success) {
        final updatedRoles = List.of(state.roles)..removeWhere((r) => r.id == id);
        emit(state.copyWith(
          roles: updatedRoles,
          isSaving: false,
        ));
        return true;
      }
      emit(state.copyWith(isSaving: false));
      return false;
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        errorMessage: 'فشل في حذف الدور: $e',
      ));
      return false;
    }
  }

  /// Saves updated permissions for a specific role.
  Future<bool> updateRolePermissions({
    required int roleId,
    required List<int> permissionIds,
  }) async {
    emit(state.copyWith(isSaving: true));
    try {
      await _rolesService.saveRolePermissions(roleId, permissionIds);

      final updatedRoles = state.roles.map((r) {
        if (r.id == roleId) {
          return r.copyWith(permissionIds: permissionIds);
        }
        return r;
      }).toList();

      emit(state.copyWith(
        roles: updatedRoles,
        isSaving: false,
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        errorMessage: 'فشل في تحديث صلاحيات الدور: $e',
      ));
      return false;
    }
  }
}
