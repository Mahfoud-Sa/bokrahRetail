/// Domain models and DTOs for Store-scoped Role-Based Access Control (RBAC).
/// Adheres strictly to canonical domain terms: "Store Member", "Operator", "Role".
/// Avoids forbidden terms like "Staff".

class StorePermissionDto {
  final String code;
  final String name;
  final String description;
  final String category;

  const StorePermissionDto({
    required this.code,
    required this.name,
    required this.description,
    required this.category,
  });

  factory StorePermissionDto.fromJson(Map<String, dynamic> json) {
    return StorePermissionDto(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'description': description,
        'category': category,
      };
}

class StoreRoleDto {
  final int id;
  final int storeId;
  final String name;
  final String? description;
  final List<String> permissionCodes;
  final int memberCount;
  final DateTime createdAtUtc;

  const StoreRoleDto({
    required this.id,
    required this.storeId,
    required this.name,
    this.description,
    required this.permissionCodes,
    required this.memberCount,
    required this.createdAtUtc,
  });

  factory StoreRoleDto.fromJson(Map<String, dynamic> json) {
    return StoreRoleDto(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      storeId: json['storeId'] is int
          ? json['storeId'] as int
          : int.tryParse(json['storeId']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      permissionCodes: (json['permissionCodes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      memberCount: json['memberCount'] is int
          ? json['memberCount'] as int
          : int.tryParse(json['memberCount']?.toString() ?? '0') ?? 0,
      createdAtUtc: json['createdAtUtc'] != null
          ? DateTime.tryParse(json['createdAtUtc'].toString()) ??
              DateTime.now().toUtc()
          : DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'storeId': storeId,
        'name': name,
        if (description != null) 'description': description,
        'permissionCodes': permissionCodes,
        'memberCount': memberCount,
        'createdAtUtc': createdAtUtc.toIso8601String(),
      };
}

class CreateStoreRoleRequest {
  final String name;
  final String? description;
  final List<String> permissionCodes;

  const CreateStoreRoleRequest({
    required this.name,
    this.description,
    required this.permissionCodes,
  });

  Map<String, dynamic> toJson() => {
        'name': name.trim(),
        if (description != null && description!.trim().isNotEmpty)
          'description': description!.trim(),
        'permissionCodes': permissionCodes,
      };
}

class UpdateStoreRoleRequest {
  final String name;
  final String? description;
  final List<String> permissionCodes;

  const UpdateStoreRoleRequest({
    required this.name,
    this.description,
    required this.permissionCodes,
  });

  Map<String, dynamic> toJson() => {
        'name': name.trim(),
        if (description != null && description!.trim().isNotEmpty)
          'description': description!.trim(),
        'permissionCodes': permissionCodes,
      };
}

class StoreMemberDto {
  final int storeId;
  final int userId;
  final String? userEmail;
  final String? userFullName;
  final String role;
  final List<int> customRoleIds;
  final List<String> customRoles;
  final List<String> effectivePermissions;
  final DateTime createdAtUtc;

  const StoreMemberDto({
    required this.storeId,
    required this.userId,
    this.userEmail,
    this.userFullName,
    required this.role,
    required this.customRoleIds,
    required this.customRoles,
    required this.effectivePermissions,
    required this.createdAtUtc,
  });

  bool get isOwner =>
      role.trim().toLowerCase() == 'owner';

  bool hasPermission(String permissionCode) {
    if (isOwner) return true;
    return effectivePermissions.contains(permissionCode);
  }

  bool hasAnyPermission(List<String> permissionCodes) {
    if (isOwner) return true;
    return permissionCodes.any(effectivePermissions.contains);
  }

  factory StoreMemberDto.fromJson(Map<String, dynamic> json) {
    return StoreMemberDto(
      storeId: json['storeId'] is int
          ? json['storeId'] as int
          : int.tryParse(json['storeId']?.toString() ?? '0') ?? 0,
      userId: json['userId'] is int
          ? json['userId'] as int
          : int.tryParse(json['userId']?.toString() ?? '0') ?? 0,
      userEmail: json['userEmail']?.toString(),
      userFullName: json['userFullName']?.toString(),
      role: json['role']?.toString() ?? 'Member',
      customRoleIds: (json['customRoleIds'] as List<dynamic>?)
              ?.map((e) => int.tryParse(e.toString()) ?? 0)
              .toList() ??
          const [],
      customRoles: (json['customRoles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      effectivePermissions: (json['effectivePermissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdAtUtc: json['createdAtUtc'] != null
          ? DateTime.tryParse(json['createdAtUtc'].toString()) ??
              DateTime.now().toUtc()
          : DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
        'storeId': storeId,
        'userId': userId,
        if (userEmail != null) 'userEmail': userEmail,
        if (userFullName != null) 'userFullName': userFullName,
        'role': role,
        'customRoleIds': customRoleIds,
        'customRoles': customRoles,
        'effectivePermissions': effectivePermissions,
        'createdAtUtc': createdAtUtc.toIso8601String(),
      };
}

class ProvisionStoreMemberRequest {
  final String email;
  final String fullName;
  final String password;
  final String role;
  final List<int> roleIds;

  const ProvisionStoreMemberRequest({
    required this.email,
    required this.fullName,
    required this.password,
    this.role = 'Member',
    this.roleIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'email': email.trim(),
        'fullName': fullName.trim(),
        'password': password,
        'role': role,
        'roleIds': roleIds,
      };
}

class AddStoreMemberRequest {
  final int userId;
  final String role;
  final List<int> roleIds;

  const AddStoreMemberRequest({
    required this.userId,
    this.role = 'Member',
    this.roleIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'role': role,
        'roleIds': roleIds,
      };
}

class UpdateMemberRolesRequest {
  final List<int> roleIds;

  const UpdateMemberRolesRequest({
    required this.roleIds,
  });

  Map<String, dynamic> toJson() => {
        'roleIds': roleIds,
      };
}
