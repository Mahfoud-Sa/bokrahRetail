import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bokrah_retail/app/features/auth/data/datasources/auth_token_storage.dart';
import 'package:bokrah_retail/app/features/auth/data/models/auth_session_model.dart';
import 'package:bokrah_retail/app/features/store/data/models/store_dto.dart';
import 'package:bokrah_retail/app/features/store/data/services/store_api_service.dart';
import 'package:bokrah_retail/app/features/store/data/services/store_service.dart';
import 'package:bokrah_retail/app/features/store/presentation/cubits/store_cubit.dart';
import 'package:bokrah_retail/app/features/store/presentation/cubits/store_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late SharedPrefsAuthTokenStorage tokenStorage;
  late StoreService storeService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    tokenStorage = SharedPrefsAuthTokenStorage(prefs: prefs);
    storeService = StoreService();
  });

  AuthSessionModel createSession({
    required String userId,
    required String token,
    List<String> roles = const ['store'],
    String? email,
    String? name,
  }) {
    return AuthSessionModel(
      userId: userId,
      phoneNumber: '+962790000000',
      accessToken: token,
      refreshToken: token,
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      roles: roles,
      email: email ?? 'owner@retail.com',
      name: name ?? 'Store Owner',
    );
  }

  group('ASP.NET Core Store API Integration Tests', () {
    test('CreateStoreRequest enforces validation constraints and default currency JOD', () {
      // Missing name
      const emptyReq = CreateStoreRequest();
      expect(emptyReq.hasValidName, isFalse);
      expect(emptyReq.validate()?['name'], isNotNull);

      // Name too short (< 2 chars)
      const shortReq = CreateStoreRequest(name: 'A');
      expect(shortReq.hasValidName, isFalse);

      // Valid store creation payload
      const validReq = CreateStoreRequest(
        name: 'Bokrah Electronics Amman',
        description: 'Specialized retail store for smartphones and electronics',
        phoneNumber: '+962790000000',
        email: 'contact@bokrah.com',
        address: 'Amman, Jordan - Wasfi Al-Tal St',
        currencyCode: 'JOD',
        isActive: true,
      );

      expect(validReq.hasValidName, isTrue);
      expect(validReq.validate(), isNull);
      expect(validReq.currencyCode, equals('JOD'));
      expect(validReq.isActive, isTrue);

      final jsonMap = validReq.toJson();
      expect(jsonMap['name'], equals('Bokrah Electronics Amman'));
      expect(jsonMap['currencyCode'], equals('JOD'));
      expect(jsonMap['isActive'], isTrue);
      expect(jsonMap['phoneNumber'], equals('+962790000000'));
      expect(jsonMap['email'], equals('contact@bokrah.com'));
      // Never send ownerUserId or sensitive auth data in request bodies
      expect(jsonMap.containsKey('ownerUserId'), isFalse);
    });

    test('POST /api/stores creates store, attaches Bearer token, and returns StoreResponse with Owner role', () async {
      await tokenStorage.saveSession(createSession(
        userId: '10',
        token: 'valid_jwt_bearer_token',
      ));

      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/api/stores'));
        expect(request.method, equals('POST'));
        expect(request.headers['Authorization'], equals('Bearer valid_jwt_bearer_token'));
        expect(request.headers['Content-Type'], equals('application/json'));

        final body = json.decode(request.body) as Map<String, dynamic>;
        expect(body['name'], equals('My New Store'));
        expect(body['currencyCode'], equals('JOD'));
        expect(body.containsKey('ownerUserId'), isFalse);

        final responseJson = {
          "id": 1,
          "ownerUserId": 10,
          "name": "My New Store",
          "description": "Store selling electronics and gadgets",
          "phoneNumber": "+962790000000",
          "email": "contact@mynewstore.com",
          "address": "Amman, Jordan",
          "currencyCode": "JOD",
          "isActive": true,
          "createdAtUtc": "2026-11-08T14:30:00Z",
          "updatedAtUtc": null,
          "currentUserRole": "Owner"
        };

        return http.Response(
          json.encode(responseJson),
          201,
          headers: {
            'content-type': 'application/json; charset=utf-8',
            'Location': '/api/stores/1',
          },
        );
      });

      final service = ApiStoreService(
        client: mockClient,
        tokenStorage: tokenStorage,
        storeService: storeService,
      );

      final response = await service.createStore(const CreateStoreRequest(
        name: 'My New Store',
        description: 'Store selling electronics and gadgets',
        phoneNumber: '+962790000000',
        email: 'contact@mynewstore.com',
        address: 'Amman, Jordan',
        currencyCode: 'JOD',
      ));

      expect(response.id, equals(1));
      expect(response.ownerUserId, equals(10));
      expect(response.currentUserRole, equals('Owner'));
      expect(response.isOwner, isTrue);
      expect(response.currencyCode, equals('JOD'));

      // Check active tenant was persisted
      final activeId = await storeService.getActiveStoreId();
      expect(activeId, equals(1));
    });

    test('POST /api/stores handles 400 Bad Request with field errors from ApiErrorResponse', () async {
      await tokenStorage.saveSession(createSession(userId: '10', token: 'jwt'));

      final mockClient = MockClient((request) async {
        final errorPayload = {
          "message": "Validation failed.",
          "errors": {
            "name": ["Store name must be between 2 and 120 characters."],
            "currencyCode": ["Currency code must be between 3 and 10 characters."]
          }
        };
        return http.Response(json.encode(errorPayload), 400);
      });

      final service = ApiStoreService(
        client: mockClient,
        tokenStorage: tokenStorage,
      );

      expect(
        () => service.createStore(const CreateStoreRequest(name: 'Valid Name Test')),
        throwsA(isA<StoreValidationException>().having(
          (e) => e.message,
          'message',
          contains('Store name must be between 2 and 120 characters.'),
        )),
      );
    });

    test('GET /api/stores returns list of accessible stores (200 OK)', () async {
      await tokenStorage.saveSession(createSession(userId: '10', token: 'jwt_token'));

      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/api/stores'));
        expect(request.method, equals('GET'));
        expect(request.headers['Authorization'], equals('Bearer jwt_token'));

        final storesArray = [
          {
            "id": 1,
            "ownerUserId": 10,
            "name": "Bokrah Flagship Amman",
            "description": "Electronics Store",
            "phoneNumber": "+962790000001",
            "email": "amman@bokrah.com",
            "address": "Amman, Jordan",
            "currencyCode": "JOD",
            "isActive": true,
            "createdAtUtc": "2026-11-08T14:30:00Z",
            "updatedAtUtc": null,
            "currentUserRole": "Owner"
          },
          {
            "id": 2,
            "ownerUserId": 25,
            "name": "Bokrah Branch Irbid",
            "description": "Branch Store",
            "phoneNumber": "+962790000002",
            "email": "irbid@bokrah.com",
            "address": "Irbid, Jordan",
            "currencyCode": "JOD",
            "isActive": true,
            "createdAtUtc": "2026-11-08T15:00:00Z",
            "updatedAtUtc": null,
            "currentUserRole": "Manager"
          }
        ];

        return http.Response(
          json.encode(storesArray),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ApiStoreService(
        client: mockClient,
        tokenStorage: tokenStorage,
        storeService: storeService,
      );

      final list = await service.getMyStores();
      expect(list.length, equals(2));
      expect(list[0].id, equals(1));
      expect(list[0].isOwner, isTrue);
      expect(list[1].id, equals(2));
      expect(list[1].isManager, isTrue);

      // Verify cached in local storeService
      final cached = await storeService.getCachedAccessibleStores();
      expect(cached.length, equals(2));
    });

    test('GET /api/stores/{id} returns details for Owner or Manager, 403 for Staff, 404 for Not Found', () async {
      await tokenStorage.saveSession(createSession(userId: '10', token: 'jwt'));

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/stores/1') {
          return http.Response(
            json.encode({
              "id": 1,
              "ownerUserId": 10,
              "name": "Bokrah Store 1",
              "currencyCode": "JOD",
              "isActive": true,
              "createdAtUtc": "2026-11-08T14:30:00Z",
              "currentUserRole": "Owner"
            }),
            200,
          );
        } else if (request.url.path == '/api/stores/999') {
          return http.Response(
            json.encode({"message": "Store does not exist or has been deleted."}),
            404,
          );
        } else if (request.url.path == '/api/stores/50') {
          return http.Response(
            json.encode({"message": "Access Denied: Restricted to Owner or Manager."}),
            403,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = ApiStoreService(
        client: mockClient,
        tokenStorage: tokenStorage,
      );

      // 200 OK
      final store = await service.getStoreById(1);
      expect(store.id, equals(1));
      expect(store.currentUserRole, equals('Owner'));

      // 403 Forbidden
      expect(
        () => service.getStoreById(50),
        throwsA(isA<StoreForbiddenException>()),
      );

      // 404 Not Found
      expect(
        () => service.getStoreById(999),
        throwsA(isA<StoreNotFoundException>()),
      );
    });

    test('StoreCubit manages multi-store switching and active tenant scoping', () async {
      final mockApi = MockStoreApiService(tokenStorage: tokenStorage);
      await tokenStorage.saveSession(createSession(userId: '10', token: 'jwt'));

      mockApi.seedStores([
        const StoreResponseDto(
          id: 1,
          ownerUserId: 10,
          name: 'Amman Store',
          currencyCode: 'JOD',
          createdAtUtc: '2026-11-08T14:30:00Z',
          currentUserRole: 'Owner',
        ),
        const StoreResponseDto(
          id: 2,
          ownerUserId: 10,
          name: 'Zarqa Store',
          currencyCode: 'JOD',
          createdAtUtc: '2026-11-08T15:00:00Z',
          currentUserRole: 'Manager',
        ),
      ]);

      final cubit = StoreCubit(
        service: storeService,
        apiService: mockApi,
      );

      await cubit.loadStore();
      await cubit.loadMyStores();

      expect(cubit.state, isA<StoreLoaded>());
      final loaded = cubit.state as StoreLoaded;
      expect(loaded.accessibleStores.length, equals(2));
      expect(loaded.activeStoreId, equals(1));

      // Switch to Zarqa Store (Tenant ID 2)
      final switched = await cubit.switchActiveStore(2);
      expect(switched, isTrue);
      expect(cubit.activeStoreId, equals(2));

      final activeInPrefs = await storeService.getActiveStoreId();
      expect(activeInPrefs, equals(2));
    });

    test('Role-based permission guards verify Owner vs Manager vs Staff capabilities', () {
      final ownerEntity = const StoreResponseDto(
        id: 1,
        ownerUserId: 10,
        name: 'Main Store',
        currencyCode: 'JOD',
        createdAtUtc: '2026-11-08T14:30:00Z',
        currentUserRole: 'Owner',
      ).toEntity();

      expect(ownerEntity.isOwner, isTrue);
      expect(ownerEntity.canManageSettings, isTrue);
      expect(ownerEntity.isReadOnlySettings, isFalse);
      expect(ownerEntity.hasSettingsAccess, isTrue);

      final managerEntity = const StoreResponseDto(
        id: 2,
        ownerUserId: 20,
        name: 'Branch Store',
        currencyCode: 'JOD',
        createdAtUtc: '2026-11-08T14:30:00Z',
        currentUserRole: 'Manager',
      ).toEntity();

      expect(managerEntity.isManager, isTrue);
      expect(managerEntity.canManageSettings, isFalse);
      expect(managerEntity.isReadOnlySettings, isTrue);
      expect(managerEntity.hasSettingsAccess, isTrue);

      final staffEntity = const StoreResponseDto(
        id: 3,
        ownerUserId: 20,
        name: 'Warehouse Store',
        currencyCode: 'JOD',
        createdAtUtc: '2026-11-08T14:30:00Z',
        currentUserRole: 'Staff',
      ).toEntity();

      expect(staffEntity.isStaff, isTrue);
      expect(staffEntity.canManageSettings, isFalse);
      expect(staffEntity.isReadOnlySettings, isFalse);
      expect(staffEntity.hasSettingsAccess, isFalse);
    });
  });
}

