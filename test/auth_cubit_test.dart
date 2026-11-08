import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bokrah_retail/app/features/auth/data/datasources/auth_token_storage.dart';
import 'package:bokrah_retail/app/features/auth/data/models/otp_response_model.dart';
import 'package:bokrah_retail/app/features/auth/data/services/mock_auth_service.dart';
import 'package:bokrah_retail/app/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:bokrah_retail/app/features/auth/presentation/cubits/auth_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthService authService;
  late SharedPrefsAuthTokenStorage tokenStorage;
  late AuthCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tokenStorage = SharedPrefsAuthTokenStorage(prefs: prefs);
    authService = MockAuthService(
      tokenStorage: tokenStorage,
      simulatedLatency: Duration.zero,
    );
    cubit = AuthCubit(authService: authService);
  });

  tearDown(() {
    cubit.close();
  });

  group('AuthCubit Email & Password Tests', () {
    test('initial state defaults to email login and idle status', () {
      expect(cubit.state.step, equals(AuthStep.login));
      expect(cubit.state.loginMethod, equals(LoginMethod.email));
      expect(cubit.state.status, equals(AuthStatus.idle));
      expect(cubit.state.canSubmitLogin, isFalse);
    });

    test('validates email and password format', () {
      cubit.setEmail('chef@bokrah.com');
      cubit.setPassword('secret123');
      expect(cubit.state.isEmailValid, isTrue);
      expect(cubit.state.isPasswordValid, isTrue);
      expect(cubit.state.canSubmitLogin, isTrue);
    });

    test('submitLogin succeeds with valid email and password', () async {
      cubit.setEmail('chef@bokrah.com');
      cubit.setPassword('secret123');
      await cubit.submitLogin();

      expect(cubit.state.status, equals(AuthStatus.authenticated));
      expect(await authService.isAuthenticated(), isTrue);
      expect(await tokenStorage.getAccessToken(), isNotNull);
    });

    test('submitLogin fails with wrong password or invalid credentials', () async {
      cubit.setEmail('chef@bokrah.com');
      cubit.setPassword('wrongpass');
      await cubit.submitLogin();

      expect(cubit.state.status, equals(AuthStatus.error));
      expect(cubit.state.errorCode, equals(AuthErrorCode.invalidCredentials));
    });

    test('toggles password visibility', () {
      expect(cubit.state.isPasswordVisible, isFalse);
      cubit.togglePasswordVisibility();
      expect(cubit.state.isPasswordVisible, isTrue);
      cubit.togglePasswordVisibility();
      expect(cubit.state.isPasswordVisible, isFalse);
    });
  });

  group('AuthCubit Phone & Password Tests', () {
    test('switches to phone login and validates phone & password', () {
      cubit.setLoginMethod(LoginMethod.phone);
      expect(cubit.state.loginMethod, equals(LoginMethod.phone));

      cubit.setPhoneNumber('501234567');
      cubit.setPassword('secret123');
      expect(cubit.state.isPhoneValid, isTrue);
      expect(cubit.state.isPasswordValid, isTrue);
      expect(cubit.state.canSubmitLogin, isTrue);
    });

    test('submitLogin succeeds with valid phone and password', () async {
      cubit.setLoginMethod(LoginMethod.phone);
      cubit.setPhoneNumber('501234567');
      cubit.setPassword('secret123');
      await cubit.submitLogin();

      expect(cubit.state.status, equals(AuthStatus.authenticated));
      expect(await authService.isAuthenticated(), isTrue);
      expect(await tokenStorage.getAccessToken(), isNotNull);
    });

    test('submitLogin fails with wrong password on phone login', () async {
      cubit.setLoginMethod(LoginMethod.phone);
      cubit.setPhoneNumber('501234567');
      cubit.setPassword('wrongpass');
      await cubit.submitLogin();

      expect(cubit.state.status, equals(AuthStatus.error));
      expect(cubit.state.errorCode, equals(AuthErrorCode.invalidCredentials));
    });
  });

  group('AuthCubit OTP Flow Tests', () {
    test('sendOtp transitions to otpVerification step with cooldown and code length', () async {
      cubit.setPhoneNumber('501234567');
      await cubit.sendOtp();

      expect(cubit.state.step, equals(AuthStep.otpVerification));
      expect(cubit.state.status, equals(AuthStatus.otpSent));
      expect(cubit.state.codeLength, equals(6));
      expect(cubit.state.resendCountdown, equals(60));
      expect(cubit.state.normalizedPhoneNumber, equals('+966501234567'));
    });

    test('verifyOtp succeeds with valid code 123456', () async {
      cubit.setPhoneNumber('501234567');
      await cubit.sendOtp();

      cubit.setOtpCode('123456');
      await cubit.verifyOtp();

      expect(cubit.state.status, equals(AuthStatus.authenticated));
      expect(await authService.isAuthenticated(), isTrue);
    });

    test('editPhoneNumber navigates back to login step while preserving phone number', () async {
      cubit.setPhoneNumber('501234567');
      await cubit.sendOtp();

      cubit.editPhoneNumber();

      expect(cubit.state.step, equals(AuthStep.login));
      expect(cubit.state.rawPhoneNumber, equals('501234567'));
    });
  });

  group('AuthCubit Guest User & Session Management Tests', () {
    test('continueAsGuest transitions status to guest and sets isGuest to true', () {
      expect(cubit.state.isGuest, isFalse);
      cubit.continueAsGuest();

      expect(cubit.state.status, equals(AuthStatus.guest));
      expect(cubit.state.isGuest, isTrue);
      expect(cubit.state.isAuthenticated, isFalse);
    });

    test('logout resets guest status to initial state', () async {
      cubit.continueAsGuest();
      expect(cubit.state.isGuest, isTrue);

      await cubit.logout();
      expect(cubit.state.status, equals(AuthStatus.idle));
      expect(cubit.state.isGuest, isFalse);
    });

    test('logout revokes session and resets authenticated user to initial state', () async {
      cubit.setEmail('chef@bokrah.com');
      cubit.setPassword('secret123');
      await cubit.submitLogin();
      expect(cubit.state.isAuthenticated, isTrue);

      await cubit.logout();
      expect(cubit.state.status, equals(AuthStatus.idle));
      expect(cubit.state.isAuthenticated, isFalse);
      expect(await authService.isAuthenticated(), isFalse);
    });

    test('checkAuthStatus detects valid saved session', () async {
      cubit.setEmail('chef@bokrah.com');
      cubit.setPassword('secret123');
      await cubit.submitLogin();

      // Create a fresh cubit with same storage
      final freshCubit = AuthCubit(authService: authService);
      expect(freshCubit.state.isAuthenticated, isFalse);

      await freshCubit.checkAuthStatus();
      expect(freshCubit.state.status, equals(AuthStatus.authenticated));
      expect(freshCubit.state.isAuthenticated, isTrue);
      freshCubit.close();
    });
  });

  group('AuthCubit Registration Tests', () {
    test('register succeeds with valid details and creates session', () async {
      final success = await cubit.register(
        name: 'Saad Al-Ghamdi',
        email: 'saad@restaurant.com',
        phoneNumber: '+966501234567',
        password: 'password123',
      );

      expect(success, isTrue);
      expect(cubit.state.status, equals(AuthStatus.authenticated));
      expect(cubit.state.isAuthenticated, isTrue);
      expect(await authService.isAuthenticated(), isTrue);
      expect(await tokenStorage.getAccessToken(), isNotNull);
    });

    test('register rejects empty name', () async {
      final success = await cubit.register(
        name: '   ',
        email: 'saad@restaurant.com',
        phoneNumber: '+966501234567',
        password: 'password123',
      );

      expect(success, isFalse);
      expect(cubit.state.status, equals(AuthStatus.error));
      expect(cubit.state.errorCode, equals(AuthErrorCode.invalidCredentials));
    });

    test('register rejects invalid email format', () async {
      final success = await cubit.register(
        name: 'Saad',
        email: 'not-an-email',
        phoneNumber: '+966501234567',
        password: 'password123',
      );

      expect(success, isFalse);
      expect(cubit.state.status, equals(AuthStatus.error));
      expect(cubit.state.errorCode, equals(AuthErrorCode.invalidCredentials));
    });

    test('register rejects short password', () async {
      final success = await cubit.register(
        name: 'Saad',
        email: 'saad@restaurant.com',
        phoneNumber: '+966501234567',
        password: '123',
      );

      expect(success, isFalse);
      expect(cubit.state.status, equals(AuthStatus.error));
      expect(cubit.state.errorCode, equals(AuthErrorCode.invalidCredentials));
    });
  });
}
