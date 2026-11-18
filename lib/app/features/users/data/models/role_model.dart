import 'permission_model.dart';

/// Representation of an administrative or operational system role.
class RoleModel {
  final int id;
  final String name;
  final List<dynamic> userRoles;
  final List<dynamic> rolePermissions;
  final List<int> permissionIds;
  final bool isDeleted;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;

  const RoleModel({
    required this.id,
    required this.name,
    this.userRoles = const [],
    this.rolePermissions = const [],
    this.permissionIds = const [],
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  /// Friendly Arabic display name for default built-in roles
  String get displayName {
    final lower = name.trim().toLowerCase();
    switch (lower) {
      case 'admin':
      case 'مسؤول':
      case 'مدير':
        return 'مسؤول النظام (Admin)';
      case 'cashier':
      case 'كاشير':
        return 'كاشير (Cashier)';
      case 'accountant':
      case 'محاسب':
        return 'محاسب (Accountant)';
      case 'delivery':
      case 'مندوب':
      case 'توصيل':
        return 'مندوب توصيل (Delivery)';
      case 'manager':
      case 'مشرف':
        return 'مشرف فرع (Manager)';
      default:
        return name;
    }
  }

  /// Whether this role is an un-deletable system critical role
  bool get isSystemRole {
    final lower = name.trim().toLowerCase();
    return lower == 'admin' || lower == 'مسؤول';
  }

  /// Creates a copy of this RoleModel with modified fields
  RoleModel copyWith({
    int? id,
    String? name,
    List<dynamic>? userRoles,
    List<dynamic>? rolePermissions,
    List<int>? permissionIds,
    bool? isDeleted,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
  }) {
    return RoleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      userRoles: userRoles ?? this.userRoles,
      rolePermissions: rolePermissions ?? this.rolePermissions,
      permissionIds: permissionIds ?? this.permissionIds,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  factory RoleModel.fromMap(Map<String, dynamic> map) {
    final id = map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? '0') ?? 0;
    final name = map['name']?.toString() ?? '';
    final userRoles = map['userRoles'] is List ? map['userRoles'] as List : const [];
    final rolePermissions = map['rolePermissions'] is List ? map['rolePermissions'] as List : const [];

    final extractedPermissionIds = <int>{};
    for (final item in rolePermissions) {
      if (item is int) {
        extractedPermissionIds.add(item);
      } else if (item is Map) {
        if (item['permissionId'] is int) {
          extractedPermissionIds.add(item['permissionId']);
        } else if (item['permissionId'] != null) {
          final parsed = int.tryParse(item['permissionId'].toString());
          if (parsed != null) extractedPermissionIds.add(parsed);
        } else if (item['id'] is int) {
          extractedPermissionIds.add(item['id']);
        }
      }
    }

    if (map['permissionIds'] is List) {
      for (final p in map['permissionIds']) {
        final parsed = p is int ? p : int.tryParse(p.toString());
        if (parsed != null) extractedPermissionIds.add(parsed);
      }
    }

    return RoleModel(
      id: id,
      name: name,
      userRoles: userRoles,
      rolePermissions: rolePermissions,
      permissionIds: extractedPermissionIds.toList(),
      isDeleted: map['isDeleted'] as bool? ?? false,
      createdAt: map['createdAt']?.toString(),
      updatedAt: map['updatedAt']?.toString(),
      deletedAt: map['deletedAt']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'userRoles': userRoles,
      'rolePermissions': rolePermissions,
      'permissionIds': permissionIds,
      'isDeleted': isDeleted,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'deletedAt': deletedAt,
    };
  }

  /// Default predefined roles used as baseline or fallback.
  static List<RoleModel> get defaultRoles => [
    RoleModel(
      id: 2,
      name: 'admin',
      permissionIds: PermissionModel.defaultPermissions.map((e) => e.id).toList(),
      createdAt: '2026-03-23T10:05:34.7152361',
    ),
    const RoleModel(
      id: 1,
      name: 'delivery',
      permissionIds: [102], // View sales orders
      createdAt: '2026-03-20T05:52:49.3348204',
    ),
    const RoleModel(
      id: 4,
      name: 'cashier',
      permissionIds: [101, 102, 103, 201], // Create/view invoices, refunds, view items
      createdAt: '2026-03-24T08:00:00.0000000',
    ),
    const RoleModel(
      id: 5,
      name: 'accountant',
      permissionIds: [102, 501, 502], // View invoices, financial reports, export
      createdAt: '2026-03-24T08:00:00.0000000',
    ),
  ];
}
