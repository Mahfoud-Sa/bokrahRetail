import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bokrah_retail/app/features/auth/data/datasources/auth_token_storage.dart';
import 'package:bokrah_retail/app/features/auth/data/models/auth_dto.dart';
import 'package:bokrah_retail/app/features/auth/data/models/auth_session_model.dart';
import 'package:bokrah_retail/app/features/auth/data/services/api_auth_service.dart';
import 'package:bokrah_retail/app/features/auth/data/services/mock_auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPrefsAuthTokenStorage tokenStorage;
  const baseUrl = 'https://api.bokrah.test';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tokenStorage = SharedPrefsAuthTokenStorage(prefs: prefs);
  });

  group('DTO Serialization & Rules', () {
    test('UserRegisterRequest serializes birthDate to UTC ISO 8601 string', () {
      final date = DateTime.utc(1995, 5, 15, 0, 0, 0);
      final request = UserRegisterRequest(
        name: 'Al-Bustan Restaurant',
        birthDate: date,
        email: 'restaurant@example.com',
        password: 'SecurePassword123!',
        phoneNumber: '+967771234567',
        address: 'Main Street, City Center',
        phoneNumbers: const [
          PhoneNumberItem(number: '+967771234567', type: 'Mobile'),
        ],
      );

      final jsonMap = request.toJson();
      expect(jsonMap['name'], equals('Al-Bustan Restaurant'));
      expect(jsonMap['birthDate'], equals('1995-05-15T00:00:00.000Z'));
      expect(jsonMap['email'], equals('restaurant@example.com'));
      expect(jsonMap['password'], equals('SecurePassword123!'));
      expect(jsonMap['phoneNumber'], equals('+967771234567'));
      expect(jsonMap['address'], equals('Main Street, City Center'));
      expect(jsonMap['phoneNumbers'], isA<List>());
      expect((jsonMap['phoneNumbers'] as List).first['number'], equals('+967771234567'));
      expect((jsonMap['phoneNumbers'] as List).first['type'], equals('Mobile'));
    });

    test('LoginResponse correctly parses JSON with roles and token', () {
      final jsonMap = {
        'id': 15,
        'name': 'Al-Bustan Restaurant',
        'email': 'restaurant@example.com',
        'isActive': true,
        'token': 'jwt_test_token_123',
        'isEmailVerified': false,
        'isAccountVerified': false,
        'roles': ['restaurant'],
      };

      final response = LoginResponse.fromJson(jsonMap);
      expect(response.id, equals(15));
      expect(response.name, equals('Al-Bustan Restaurant'));
      expect(response.email, equals('restaurant@example.com'));
      expect(response.isActive, isTrue);
      expect(response.token, equals('jwt_test_token_123'));
      expect(response.isEmailVerified, isFalse);
      expect(response.isAccountVerified, isFalse);
      expect(response.roles, contains('restaurant'));
    });

    test('AuthUserResponse correctly parses registration response', () {
      final jsonMap = {
        'id': 15,
        'name': 'Al-Bustan Restaurant',
        'email': 'restaurant@example.com',
        'isActive': true,
        'roles': ['Restaurant'],
      };

      final response = AuthUserResponse.fromJson(jsonMap);
      expect(response.id, equals(15));
      expect(response.name, equals('Al-Bustan Restaurant'));
      expect(response.roles, contains('Restaurant'));
    });
  });

  group('ApiAuthService - Restaurant Registration Tests', () {
    test('POST /api/auth/register/restaurant succeeds and saves token session', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('POST'));
        expect(request.headers['Content-Type'], equals('application/json'));

        if (request.url.path == '/api/auth/register/restaurant') {
          final payload = json.decode(request.body) as Map<String, dynamic>;
          expect(payload['name'], equals('Al-Bustan Restaurant'));
          expect(payload['email'], equals('restaurant@example.com'));
          expect(payload['phoneNumber'], equals('+967771234567'));
          expect(payload['birthDate'], contains('1995-05-15'));

          return http.Response(
            json.encode({
              'id': 15,
              'name': 'Al-Bustan Restaurant',
              'email': 'restaurant@example.com',
              'isActive': true,
              'roles': ['Restaurant'],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        // Automatic login to acquire token after register
        if (request.url.path == '/api/auth/login') {
          return http.Response(
            json.encode({
              'id': 15,
              'name': 'Al-Bustan Restaurant',
              'email': 'restaurant@example.com',
              'isActive': true,
              'token': 'jwt_real_token_15',
              'isEmailVerified': false,
              'isAccountVerified': false,
              'roles': ['restaurant'],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response('Not Found', 404);
      });

      final service = ApiAuthService(
        client: mockClient,
        tokenStorage: tokenStorage,
        baseUrl: baseUrl,
      );

      final session = await service.register(
        name: 'Al-Bustan Restaurant',
        birthDate: DateTime.utc(1995, 5, 15),
        email: 'restaurant@example.com',
        password: 'SecurePassword123!',
        phoneNumber: '+967771234567',
        address: 'Main Street, City Center',
        role: RegistrationRole.restaurant,
      );

      expect(session.accessToken, equals('jwt_real_token_15'));
      expect(session.isRestaurant, isTrue);
      expect(await tokenStorage.getAccessToken(), equals('jwt_real_token_15'));

      // Check Authorization Bearer header
      final authHeaders = await service.getAuthHeaders();
      expect(authHeaders['Authorization'], equals('Bearer jwt_real_token_15'));
      expect(authHeaders['Content-Type'], equals('application/json'));
    });

    test('POST /api/auth/register/restaurant surfaces 400 Email already exists.', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({'message': 'Email already exists.'}),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ApiAuthService(
        client: mockClient,
        tokenStorage: tokenStorage,
        baseUrl: baseUrl,
      );

      expect(
        () => service.register(
          name: 'Al-Bustan Restaurant',
          birthDate: DateTime.utc(1995, 5, 15),
          email: 'duplicate@example.com',
          password: 'SecurePassword123!',
          phoneNumber: '+967771234567',
        ),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          contains('Email already exists.'),
        )),
      );
    });

    test('POST /api/auth/register/restaurant surfaces 409 Conflict duplicate name', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({'message': 'A restaurant with the same name already exists.'}),
          409,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ApiAuthService(
        client: mockClient,
        tokenStorage: tokenStorage,
        baseUrl: baseUrl,
      );

      expect(
        () => service.register(
          name: 'Al-Bustan Restaurant',
          birthDate: DateTime.utc(1995, 5, 15),
          email: 'newemail@example.com',
          password: 'SecurePassword123!',
          phoneNumber: '+967771234567',
        ),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          contains('A restaurant with the same name already exists.'),
        )),
      );
    });

    test('supports customer, delivery, and admin registration endpoints', () async {
      final requestedPaths = <String>[];
      final mockClient = MockClient((request) async {
        requestedPaths.add(request.url.path);
        return http.Response(
          json.encode({
            'id': 99,
            'name': 'Test User',
            'email': 'user@example.com',
            'isActive': true,
            'token': 'mock_token',
            'roles': ['Customer'],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ApiAuthService(
        client: mockClient,
        tokenStorage: tokenStorage,
        baseUrl: baseUrl,
      );

      await service.register(
        name: 'Customer 1',
        email: 'c@test.com',
        phoneNumber: '+967771111111',
        password: 'password123',
        role: RegistrationRole.customer,
      );
      expect(requestedPaths.last, equals('/api/auth/register/customer'));

      await service.register(
        name: 'Delivery 1',
        email: 'd@test.com',
        phoneNumber: '+967772222222',
        password: 'password123',
        role: RegistrationRole.delivery,
      );
      expect(requestedPaths.last, equals('/api/auth/register/delivery'));

      await service.register(
        name: 'Admin 1',
        email: 'a@test.com',
        phoneNumber: '+967773333333',
        password: 'password123',
        role: RegistrationRole.admin,
      );
      expect(requestedPaths.last, equals('/api/auth/register/admin'));
    });
  });

  group('ApiAuthService - Login Tests', () {
    test('POST /api/auth/login succeeds with valid credentials', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/api/auth/login'));
        expect(request.headers['Content-Type'], equals('application/json'));

        final body = json.decode(request.body) as Map<String, dynamic>;
        expect(body['email'], equals('restaurant@example.com'));
        expect(body['password'], equals('SecurePassword123!'));

        return http.Response(
          json.encode({
            'id': 15,
            'name': 'Al-Bustan Restaurant',
            'email': 'restaurant@example.com',
            'isActive': true,
            'token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MTV9',
            'isEmailVerified': false,
            'isAccountVerified': false,
            'roles': ['restaurant'],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ApiAuthService(
        client: mockClient,
        tokenStorage: tokenStorage,
        baseUrl: baseUrl,
      );

      final session = await service.loginWithEmailAndPassword(
        email: 'restaurant@example.com',
        password: 'SecurePassword123!',
      );

      expect(session.userId, equals('15'));
      expect(session.accessToken, startsWith('eyJhbGciOi'));
      expect(session.roles, contains('restaurant'));
      expect(session.isRestaurant, isTrue);
      expect(await tokenStorage.getAccessToken(), startsWith('eyJhbGciOi'));
    });

    test('POST /api/auth/login handles 401 Invalid email or password', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({'message': 'Invalid email or password'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ApiAuthService(
        client: mockClient,
        tokenStorage: tokenStorage,
        baseUrl: baseUrl,
      );

      expect(
        () => service.loginWithEmailAndPassword(
          email: 'restaurant@example.com',
          password: 'wrongpassword',
        ),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          equals('Invalid email or password. Please try again.'),
        )),
      );
    });

    test('POST /api/auth/login handles 404 User not found', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({'message': 'User not found'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ApiAuthService(
        client: mockClient,
        tokenStorage: tokenStorage,
        baseUrl: baseUrl,
      );

      expect(
        () => service.loginWithEmailAndPassword(
          email: 'nonexistent@example.com',
          password: 'password123',
        ),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          equals('No account found with this email address.'),
        )),
      );
    });

    test('POST /api/auth/login handles 401 User account is deactivated', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({'message': 'User account is deactivated'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ApiAuthService(
        client: mockClient,
        tokenStorage: tokenStorage,
        baseUrl: baseUrl,
      );

      expect(
        () => service.loginWithEmailAndPassword(
          email: 'deactivated@example.com',
          password: 'password123',
        ),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          equals('Your account has been deactivated. Please contact support.'),
        )),
      );
    });

    test('POST /api/auth/login handles 400 Bad Request missing credentials', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({'message': 'Email is required'}),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ApiAuthService(
        client: mockClient,
        tokenStorage: tokenStorage,
        baseUrl: baseUrl,
      );

      // Local validation blocks empty
      expect(
        () => service.loginWithEmailAndPassword(
          email: '   ',
          password: 'password123',
        ),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          equals('Please enter both email and password.'),
        )),
      );

      // Remote 400 response
      expect(
        () => service.loginWithEmailAndPassword(
          email: 'user@example.com',
          password: 'password123',
        ),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          equals('Please enter both email and password.'),
        )),
      );
    });

    test('POST /api/auth/login handles 500 Server Error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          'Internal server error',
          500,
          headers: {'content-type': 'text/plain'},
        );
      });

      final service = ApiAuthService(
        client: mockClient,
        tokenStorage: tokenStorage,
        baseUrl: baseUrl,
      );

      expect(
        () => service.loginWithEmailAndPassword(
          email: 'user@example.com',
          password: 'password123',
        ),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          equals('Something went wrong. Please try again later.'),
        )),
      );
    });

    test('getAuthHeaders attaches Authorization Bearer token', () async {
      final service = ApiAuthService(
        tokenStorage: tokenStorage,
        baseUrl: baseUrl,
      );

      // Before login, no auth token
      final headersBefore = await service.getAuthHeaders();
      expect(headersBefore['Content-Type'], equals('application/json'));
      expect(headersBefore.containsKey('Authorization'), isFalse);

      // Save a valid session
      await tokenStorage.saveSession(AuthSessionModel(
        userId: '15',
        phoneNumber: '+967771234567',
        accessToken: 'secure_jwt_token_sample',
        refreshToken: 'refresh_token_sample',
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      ));

      final headersAfter = await service.getAuthHeaders();
      expect(headersAfter['Content-Type'], equals('application/json'));
      expect(headersAfter['Authorization'], equals('Bearer secure_jwt_token_sample'));
    });
  });
}
