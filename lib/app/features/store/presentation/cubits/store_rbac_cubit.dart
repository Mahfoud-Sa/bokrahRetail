import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/store_rbac_models.dart';
import '../../data/services/store_api_service.dart';
import 'store_rbac_state.dart';

class StoreRbacCubit extends Cubit<StoreRbacState> {
  final StoreApiService _apiService;

  StoreRbacCubit({required StoreApiService apiService})
      : _apiService = apiService,
        super(const StoreRbacState());

  /// Loads permissions catalog, store roles, and store members for [storeId].
  /// Matches [currentUserId] to determine the active operator's effective permissions.
  Future<void> loadStoreRbacContext(int storeId, {int? currentUserId}) async {
    emit(state.copyWith(status: StoreRbacStatus.loading, storeId: storeId));

    try {
      final results = await Future.wait([
        state.permissionCatalog.isEmpty
            ? _apiService.getPermissionCatalog()
            : Future.value(state.permissionCatalog),
        _apiService.getStoreRoles(storeId),
        _apiService.getStoreMembers(storeId),
      ]);

      final catalog = results[0] as List<StorePermissionDto>;
      final roles = results[1] as List<StoreRoleDto>;
      final members = results[2] as List<StoreMemberDto>;

      StoreMemberDto? activeMember;
      if (currentUserId != null) {
        try {
          activeMember = members.firstWhere((m) => m.userId == currentUserId);
        } catch (_) {
          // If current user is owner or not in list, check if any member matches
          activeMember = null;
        }
      } else if (members.isNotEmpty) {
        activeMember = members.first;
      }

      emit(state.copyWith(
        status: StoreRbacStatus.loaded,
        storeId: storeId,
        permissionCatalog: catalog,
        roles: roles,
        members: members,
        currentMember: activeMember,
        clearMessages: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: StoreRbacStatus.error,
        errorMessage: 'فشل في تحميل بيانات الأدوار والأعضاء: $e',
      ));
    }
  }

  /// Creates a new custom role with assigned permission codes
  Future<bool> createRole({
    required String name,
    String? description,
    required List<String> permissionCodes,
  }) async {
    final storeId = state.storeId;
    if (storeId == null) return false;

    emit(state.copyWith(isSaving: true, clearMessages: true));
    try {
      final created = await _apiService.createStoreRole(
        storeId,
        CreateStoreRoleRequest(
          name: name,
          description: description,
          permissionCodes: permissionCodes,
        ),
      );

      final updatedRoles = List<StoreRoleDto>.from(state.roles)
        ..removeWhere((r) => r.id == created.id)
        ..add(created);

      emit(state.copyWith(
        roles: updatedRoles,
        isSaving: false,
        successMessage: 'تم إنشاء الدور بنجاح',
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

  /// Updates an existing custom role
  Future<bool> updateRole({
    required int roleId,
    required String name,
    String? description,
    required List<String> permissionCodes,
  }) async {
    final storeId = state.storeId;
    if (storeId == null) return false;

    emit(state.copyWith(isSaving: true, clearMessages: true));
    try {
      final updated = await _apiService.updateStoreRole(
        storeId,
        roleId,
        UpdateStoreRoleRequest(
          name: name,
          description: description,
          permissionCodes: permissionCodes,
        ),
      );

      final updatedRoles = List<StoreRoleDto>.from(state.roles);
      final index = updatedRoles.indexWhere((r) => r.id == roleId);
      if (index != -1) {
        updatedRoles[index] = updated;
      }

      emit(state.copyWith(
        roles: updatedRoles,
        isSaving: false,
        successMessage: 'تم تحديث الدور بنجاح',
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        errorMessage: 'فشل في تحديث الدور: $e',
      ));
      return false;
    }
  }

  /// Deletes a custom role from the store
  Future<bool> deleteRole(int roleId) async {
    final storeId = state.storeId;
    if (storeId == null) return false;

    emit(state.copyWith(isSaving: true, clearMessages: true));
    try {
      await _apiService.deleteStoreRole(storeId, roleId);
      final updatedRoles =
          List<StoreRoleDto>.from(state.roles)..removeWhere((r) => r.id == roleId);

      emit(state.copyWith(
        roles: updatedRoles,
        isSaving: false,
        successMessage: 'تم حذف الدور بنجاح',
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        errorMessage: 'فشل في حذف الدور: $e',
      ));
      return false;
    }
  }

  /// Provisions a new member account or assigns an existing user by email
  Future<bool> provisionMember({
    required String email,
    required String fullName,
    required String password,
    String role = 'Member',
    List<int> roleIds = const [],
  }) async {
    final storeId = state.storeId;
    if (storeId == null) return false;

    emit(state.copyWith(isSaving: true, clearMessages: true));
    try {
      final created = await _apiService.provisionMember(
        storeId,
        ProvisionStoreMemberRequest(
          email: email,
          fullName: fullName,
          password: password,
          role: role,
          roleIds: roleIds,
        ),
      );

      final updatedMembers = List<StoreMemberDto>.from(state.members)
        ..removeWhere((m) => m.userId == created.userId)
        ..add(created);

      emit(state.copyWith(
        members: updatedMembers,
        isSaving: false,
        successMessage: 'تمت إضافة عضو المتجر بنجاح',
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        errorMessage: 'فشل في إضافة العضو: $e',
      ));
      return false;
    }
  }

  /// Updates custom roles assigned to an existing member
  Future<bool> updateMemberRoles({
    required int userId,
    required List<int> roleIds,
  }) async {
    final storeId = state.storeId;
    if (storeId == null) return false;

    emit(state.copyWith(isSaving: true, clearMessages: true));
    try {
      final updated = await _apiService.updateMemberRoles(
        storeId,
        userId,
        UpdateMemberRolesRequest(roleIds: roleIds),
      );

      final updatedMembers = List<StoreMemberDto>.from(state.members);
      final index = updatedMembers.indexWhere((m) => m.userId == userId);
      if (index != -1) {
        updatedMembers[index] = updated;
      }

      emit(state.copyWith(
        members: updatedMembers,
        isSaving: false,
        successMessage: 'تم تحديث أدوار العضو بنجاح',
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        errorMessage: 'فشل في تحديث أدوار العضو: $e',
      ));
      return false;
    }
  }

  /// Removes a member from the store
  Future<bool> removeMember(int userId) async {
    final storeId = state.storeId;
    if (storeId == null) return false;

    emit(state.copyWith(isSaving: true, clearMessages: true));
    try {
      await _apiService.removeMember(storeId, userId);
      final updatedMembers = List<StoreMemberDto>.from(state.members)
        ..removeWhere((m) => m.userId == userId);

      emit(state.copyWith(
        members: updatedMembers,
        isSaving: false,
        successMessage: 'تمت إزالة العضو من المتجر',
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        errorMessage: 'فشل في إزالة العضو: $e',
      ));
      return false;
    }
  }
}
