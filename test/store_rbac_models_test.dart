import 'package:flutter_test/flutter_test.dart';
import 'package:bokrah_retail/app/features/store/data/models/store_rbac_models.dart';

void main() {
  group('StorePermissionDto', () {
    test('deserializes from JSON correctly', () {
      final json = {
        'code': 'store.orders.manage',
        'name': 'Manage Orders',
        'description': 'Allows creating and editing orders',
        'category': 'Orders',
      };

      final dto = StorePermissionDto.fromJson(json);

      expect(dto.code, equals('store.orders.manage'));
      expect(dto.name, equals('Manage Orders'));
      expect(dto.description, equals('Allows creating and editing orders'));
      expect(dto.category, equals('Orders'));
    });
  });

  group('StoreRoleDto', () {
    test('deserializes and serializes JSON correctly', () {
      final json = {
        'id': 101,
        'storeId': 12,
        'name': 'Cashier',
        'description': 'Handles POS register',
        'permissionCodes': ['store.invoices.view', 'store.invoices.manage'],
        'memberCount': 3,
        'createdAtUtc': '2026-11-19T17:10:00.000Z',
      };

      final dto = StoreRoleDto.fromJson(json);

      expect(dto.id, equals(101));
      expect(dto.storeId, equals(12));
      expect(dto.name, equals('Cashier'));
      expect(dto.permissionCodes, contains('store.invoices.manage'));
      expect(dto.memberCount, equals(3));
      expect(dto.createdAtUtc, isNotNull);

      final req = CreateStoreRoleRequest(
        name: 'Supervisor',
        description: 'Supervises floor',
        permissionCodes: ['store.orders.view'],
      );
      final reqJson = req.toJson();
      expect(reqJson['name'], equals('Supervisor'));
      expect(reqJson['permissionCodes'], equals(['store.orders.view']));
    });
  });

  group('StoreMemberDto & Permissions Evaluation', () {
    test('evaluates permissions for regular member', () {
      final json = {
        'storeId': 12,
        'userId': 5,
        'userEmail': 'clerk@store.com',
        'userFullName': 'Sami Clerk',
        'role': 'Member',
        'customRoleIds': [101],
        'customRoles': ['Cashier'],
        'effectivePermissions': [
          'store.invoices.view',
          'store.invoices.manage',
          'store.orders.view',
        ],
        'createdAtUtc': '2026-11-19T17:15:00.000Z',
      };

      final member = StoreMemberDto.fromJson(json);

      expect(member.isOwner, isFalse);
      expect(member.hasPermission('store.invoices.view'), isTrue);
      expect(member.hasPermission('store.roles.manage'), isFalse);
      expect(
        member.hasAnyPermission(['store.roles.manage', 'store.orders.view']),
        isTrue,
      );
      expect(
        member.hasAnyPermission(['store.roles.manage', 'store.members.manage']),
        isFalse,
      );
    });

    test('Store Owner automatically inherits full permissions', () {
      final json = {
        'storeId': 12,
        'userId': 1,
        'userEmail': 'owner@store.com',
        'userFullName': 'Omar Owner',
        'role': 'Owner',
        'customRoleIds': <int>[],
        'customRoles': <String>[],
        'effectivePermissions': <String>[],
        'createdAtUtc': '2026-11-19T16:00:00.000Z',
      };

      final owner = StoreMemberDto.fromJson(json);

      expect(owner.isOwner, isTrue);
      // Implicit superuser rights: hasPermission returns true regardless of effectivePermissions list
      expect(owner.hasPermission('store.roles.manage'), isTrue);
      expect(owner.hasPermission('store.members.manage'), isTrue);
      expect(owner.hasPermission('store.settings.manage'), isTrue);
      expect(owner.hasAnyPermission(['non.existent.code']), isTrue);
    });

    test('member provisioning request serializes properly', () {
      final req = ProvisionStoreMemberRequest(
        email: 'newuser@example.com',
        fullName: 'New User',
        password: 'Password123!',
        role: 'Member',
        roleIds: [101, 102],
      );

      final json = req.toJson();
      expect(json['email'], equals('newuser@example.com'));
      expect(json['role'], equals('Member'));
      expect(json['roleIds'], equals([101, 102]));
    });
  });
}
