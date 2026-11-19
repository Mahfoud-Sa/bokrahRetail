import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:bokrah_retail/app/features/auth/data/datasources/auth_token_storage.dart';
import 'package:bokrah_retail/app/features/auth/data/models/auth_session_model.dart';
import 'package:bokrah_retail/app/features/store/data/models/store_rbac_models.dart';
import 'package:bokrah_retail/app/features/store/data/services/store_api_service.dart';

class FakeTokenStorage implements AuthTokenStorage {
  final AuthSessionModel? session;
  FakeTokenStorage(this.session);

  @override
  Future<AuthSessionModel?> getSession() async => session;

  @override
  Future<String?> getAccessToken() async => session?.accessToken;

  @override
  Future<void> saveSession(AuthSessionModel session) async {}

  @override
  Future<void> clearSession() async {}

  @override
  Future<bool> hasValidSession() async => session != null && !session!.isExpired;
}

void main() {
  final dummySession = AuthSessionModel(
    userId: '1',
    phoneNumber: '+962791112233',
    accessToken: 'test_token',
    refreshToken: 'refresh',
    expiresAt: DateTime.now().add(const Duration(hours: 1)),
    roles: ['Owner'],
  );

  group('StoreApiService Store-Scoped RBAC', () {
    test('getPermissionCatalog sends GET /api/stores/permissions/catalog', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('GET'));
        expect(request.url.path, equals('/api/stores/permissions/catalog'));
        expect(request.headers['Authorization'], equals('Bearer test_token'));

        return http.Response(
          json.encode([
            {
              'code': 'store.orders.view',
              'name': 'View Orders',
              'description': 'View orders',
              'category': 'Orders',
            }
          ]),
          200,
        );
      });

      final service = ApiStoreService(
        client: mockClient,
        tokenStorage: FakeTokenStorage(dummySession),
        baseUrlOverride: 'http://localhost',
      );

      final catalog = await service.getPermissionCatalog();
      expect(catalog.length, equals(1));
      expect(catalog.first.code, equals('store.orders.view'));
    });

    test('getStoreRoles sends GET /api/stores/{storeId}/roles', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('GET'));
        expect(request.url.path, equals('/api/stores/12/roles'));

        return http.Response(
          json.encode([
            {
              'id': 101,
              'storeId': 12,
              'name': 'Cashier',
              'permissionCodes': ['store.orders.view'],
              'memberCount': 2,
              'createdAtUtc': '2026-11-19T17:00:00Z',
            }
          ]),
          200,
        );
      });

      final service = ApiStoreService(
        client: mockClient,
        tokenStorage: FakeTokenStorage(dummySession),
        baseUrlOverride: 'http://localhost',
      );

      final roles = await service.getStoreRoles(12);
      expect(roles.length, equals(1));
      expect(roles.first.id, equals(101));
      expect(roles.first.name, equals('Cashier'));
    });

    test('provisionMember sends POST /api/stores/{storeId}/members/provision', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('POST'));
        expect(request.url.path, equals('/api/stores/12/members/provision'));
        final body = json.decode(request.body);
        expect(body['email'], equals('employee@store.com'));
        expect(body['roleIds'], equals([101]));

        return http.Response(
          json.encode({
            'storeId': 12,
            'userId': 9,
            'userEmail': 'employee@store.com',
            'userFullName': 'New Employee',
            'role': 'Member',
            'customRoleIds': [101],
            'customRoles': ['Cashier'],
            'effectivePermissions': ['store.orders.view'],
            'createdAtUtc': '2026-11-19T17:00:00Z',
          }),
          201,
        );
      });

      final service = ApiStoreService(
        client: mockClient,
        tokenStorage: FakeTokenStorage(dummySession),
        baseUrlOverride: 'http://localhost',
      );

      final member = await service.provisionMember(
        12,
        const ProvisionStoreMemberRequest(
          email: 'employee@store.com',
          fullName: 'New Employee',
          password: 'SecretPassword123!',
          role: 'Member',
          roleIds: [101],
        ),
      );

      expect(member.userId, equals(9));
      expect(member.hasPermission('store.orders.view'), isTrue);
    });

    test('throws StoreForbiddenException on 403', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({'message': 'User lacks store.roles.manage permission'}),
          403,
        );
      });

      final service = ApiStoreService(
        client: mockClient,
        tokenStorage: FakeTokenStorage(dummySession),
        baseUrlOverride: 'http://localhost',
      );

      expect(
        () => service.deleteStoreRole(12, 101),
        throwsA(isA<StoreForbiddenException>()),
      );
    });
  });
}
