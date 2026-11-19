import 'package:equatable/equatable.dart';
import '../../data/models/store_rbac_models.dart';

enum StoreRbacStatus { initial, loading, loaded, error }

class StoreRbacState extends Equatable {
  final StoreRbacStatus status;
  final int? storeId;
  final List<StorePermissionDto> permissionCatalog;
  final List<StoreRoleDto> roles;
  final List<StoreMemberDto> members;
  final StoreMemberDto? currentMember;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  const StoreRbacState({
    this.status = StoreRbacStatus.initial,
    this.storeId,
    this.permissionCatalog = const [],
    this.roles = const [],
    this.members = const [],
    this.currentMember,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  bool get isCurrentMemberOwner =>
      currentMember?.isOwner ?? false;

  List<String> get currentPermissions =>
      currentMember?.effectivePermissions ?? const [];

  bool can(String permissionCode) {
    if (isCurrentMemberOwner) return true;
    return currentPermissions.contains(permissionCode);
  }

  bool canAny(List<String> permissionCodes) {
    if (isCurrentMemberOwner) return true;
    return permissionCodes.any(currentPermissions.contains);
  }

  /// Groups system permissions by category for intuitive display in role authoring forms
  Map<String, List<StorePermissionDto>> get groupedPermissions {
    final map = <String, List<StorePermissionDto>>{};
    for (final perm in permissionCatalog) {
      final category = perm.category.isNotEmpty ? perm.category : 'General';
      map.putIfAbsent(category, () => []).add(perm);
    }
    return map;
  }

  StoreRbacState copyWith({
    StoreRbacStatus? status,
    int? storeId,
    List<StorePermissionDto>? permissionCatalog,
    List<StoreRoleDto>? roles,
    List<StoreMemberDto>? members,
    StoreMemberDto? currentMember,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return StoreRbacState(
      status: status ?? this.status,
      storeId: storeId ?? this.storeId,
      permissionCatalog: permissionCatalog ?? this.permissionCatalog,
      roles: roles ?? this.roles,
      members: members ?? this.members,
      currentMember: currentMember ?? this.currentMember,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        storeId,
        permissionCatalog,
        roles,
        members,
        currentMember,
        isSaving,
        errorMessage,
        successMessage,
      ];
}
