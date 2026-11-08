import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bokrah_retail/app/features/auth/data/datasources/auth_token_storage.dart';
import 'package:bokrah_retail/app/features/auth/data/models/auth_session_model.dart';
import 'package:bokrah_retail/app/features/restaurant/data/models/restaurant_dto.dart';
import 'package:bokrah_retail/app/features/restaurant/data/services/restaurant_api_service.dart';
import 'package:bokrah_retail/app/features/restaurant/data/services/restaurant_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late SharedPrefsAuthTokenStorage tokenStorage;
  late RestaurantService localRestaurantService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    tokenStorage = SharedPrefsAuthTokenStorage(prefs: prefs);
    localRestaurantService = RestaurantService();
  });

  AuthSessionModel createSession({
    required String userId,
    required String token,
    List<String> roles = const ['restaurant'],
    String? email,
    String? name,
  }) {
    return AuthSessionModel(
      userId: userId,
      phoneNumber: '+966501234567',
      accessToken: token,
      refreshToken: token,
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      roles: roles,
      email: email,
      name: name,
    );
  }

  group('ApiRestaurantService HTTP Integration Tests', () {
    test('POST /api/restaurants succeeds (201 Created) and attaches Bearer token', () async {
      await tokenStorage.saveSession(createSession(
        userId: '45',
        name: 'Ahmed Ali',
        email: 'restaurant@example.com',
        token: 'test_valid_jwt_token',
        roles: ['restaurant'],
      ));

      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/api/restaurants'));
        expect(request.method, equals('POST'));
        expect(request.headers['Authorization'], equals('Bearer test_valid_jwt_token'));
        expect(request.headers['Content-Type'], equals('application/json'));

        final responseJson = {
          "id": 12,
          "name": "Al-Saada Restaurant",
          "nameAr": "مطعم السعادة",
          "nameEn": "Al-Saada Restaurant",
          "slogan": "The Real Taste of Joy",
          "subtitle": "Traditional & Modern Cuisine",
          "description": "Family-friendly restaurant offering high-quality dishes.",
          "address": "King Fahd Road, Riyadh, Saudi Arabia",
          "googleMapsUrl": "https://maps.google.com/?q=24.7136,46.6753",
          "latitude": 24.7136,
          "longitude": 46.6753,
          "websiteUrl": "https://alsaada-restaurant.com",
          "phone": "+966501234567",
          "userId": 45,
          "ownerName": "Ahmed Ali",
          "phoneNumbers": [
            {
              "id": 101,
              "number": "+966501234567",
              "type": "Mobile"
            }
          ]
        };

        return http.Response(
          json.encode(responseJson),
          201,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = ApiRestaurantService(
        client: mockClient,
        tokenStorage: tokenStorage,
        localRestaurantService: localRestaurantService,
      );

      final result = await service.createRestaurant(const CreateRestaurantRequest(
        nameAr: 'مطعم السعادة',
        nameEn: 'Al-Saada Restaurant',
        slogan: 'The Real Taste of Joy',
        phone: '+966501234567',
      ));

      expect(result.id, equals(12));
      expect(result.nameAr, equals('مطعم السعادة'));
      expect(result.ownerName, equals('Ahmed Ali'));

      // Verify local storage is synchronized
      final localInfo = await localRestaurantService.getRestaurantInfo();
      expect(localInfo.nameAr, equals('مطعم السعادة'));
      expect(localInfo.slogan, equals('The Real Taste of Joy'));
    });

    test('Throws RestaurantValidationException (400) when name is missing', () async {
      await tokenStorage.saveSession(createSession(
        userId: '1',
        name: 'User',
        email: 'user@example.com',
        token: 'token',
        roles: ['restaurant'],
      ));

      final service = ApiRestaurantService(
        tokenStorage: tokenStorage,
      );

      expect(
        () => service.createRestaurant(const CreateRestaurantRequest(slogan: 'Only slogan')),
        throwsA(isA<RestaurantValidationException>()),
      );
    });

    test('Throws RestaurantUnauthorizedException (401) when token is missing', () async {
      final service = ApiRestaurantService(
        tokenStorage: tokenStorage,
      );

      expect(
        () => service.createRestaurant(const CreateRestaurantRequest(name: 'Valid Name')),
        throwsA(isA<RestaurantUnauthorizedException>()),
      );
    });

    test('Throws RestaurantForbiddenException (403) when user lacks restaurant or admin role', () async {
      await tokenStorage.saveSession(createSession(
        userId: '2',
        name: 'Customer User',
        email: 'customer@example.com',
        token: 'valid_token',
        roles: ['customer'],
      ));

      final service = ApiRestaurantService(
        tokenStorage: tokenStorage,
      );

      expect(
        () => service.createRestaurant(const CreateRestaurantRequest(name: 'Valid Name')),
        throwsA(isA<RestaurantForbiddenException>()),
      );
    });

    test('Handles 409 Conflict: owner already has a restaurant', () async {
      await tokenStorage.saveSession(createSession(
        userId: '3',
        name: 'Owner',
        email: 'owner@example.com',
        token: 'valid_token',
        roles: ['restaurant'],
      ));

      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({'message': 'A restaurant owner can only add one restaurant.'}),
          409,
        );
      });

      final service = ApiRestaurantService(
        client: mockClient,
        tokenStorage: tokenStorage,
      );

      expect(
        () => service.createRestaurant(const CreateRestaurantRequest(name: 'Valid Name')),
        throwsA(isA<RestaurantOwnerAlreadyHasRestaurantException>()),
      );
    });

    test('Handles 409 Conflict: duplicate restaurant name', () async {
      await tokenStorage.saveSession(createSession(
        userId: '4',
        name: 'Admin',
        email: 'admin@example.com',
        token: 'valid_token',
        roles: ['admin'],
      ));

      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({'message': 'A restaurant with the same name already exists.'}),
          409,
        );
      });

      final service = ApiRestaurantService(
        client: mockClient,
        tokenStorage: tokenStorage,
      );

      expect(
        () => service.createRestaurant(const CreateRestaurantRequest(name: 'Existing Name')),
        throwsA(isA<RestaurantDuplicateNameException>()),
      );
    });

    test('Handles 500 Internal Server Error', () async {
      await tokenStorage.saveSession(createSession(
        userId: '5',
        name: 'Owner',
        email: 'owner@example.com',
        token: 'valid_token',
        roles: ['restaurant'],
      ));

      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final service = ApiRestaurantService(
        client: mockClient,
        tokenStorage: tokenStorage,
      );

      expect(
        () => service.createRestaurant(const CreateRestaurantRequest(name: 'Valid Name')),
        throwsA(isA<RestaurantServerException>()),
      );
    });
  });

  group('MockRestaurantApiService Business Rules Tests', () {
    test('enforces owner-single-restaurant rule and unique names', () async {
      final mock = MockRestaurantApiService(
        tokenStorage: tokenStorage,
        simulatedLatency: Duration.zero,
        localRestaurantService: localRestaurantService,
      );

      await tokenStorage.saveSession(createSession(
        userId: '10',
        name: 'Owner 1',
        email: 'owner1@example.com',
        token: 'token1',
        roles: ['restaurant'],
      ));

      final res = await mock.createRestaurant(const CreateRestaurantRequest(
        nameAr: 'مطعم الأمل',
        nameEn: 'Al Amal Restaurant',
      ));
      expect(res.nameAr, equals('مطعم الأمل'));

      // Second attempt by same owner must throw 409 owner already has restaurant
      expect(
        () => mock.createRestaurant(const CreateRestaurantRequest(
          nameAr: 'مطعم آخر',
          nameEn: 'Another Restaurant',
        )),
        throwsA(isA<RestaurantOwnerAlreadyHasRestaurantException>()),
      );

      // Another owner trying to use same name must throw 409 duplicate name
      await tokenStorage.saveSession(createSession(
        userId: '11',
        name: 'Owner 2',
        email: 'owner2@example.com',
        token: 'token2',
        roles: ['restaurant'],
      ));

      expect(
        () => mock.createRestaurant(const CreateRestaurantRequest(
          nameAr: 'مطعم الأمل',
        )),
        throwsA(isA<RestaurantDuplicateNameException>()),
      );
    });
  });
}
