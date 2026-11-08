import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/auth_dto.dart';
import '../../data/models/country_code_model.dart';
import '../../data/models/otp_response_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/mock_auth_service.dart';
import 'auth_state.dart';
import 'package:bokrah_retail/app/initialzation_dependencies.dart';
import 'package:bokrah_retail/app/features/restaurant/presentation/cubits/restaurant_cubit.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;
  Timer? _countdownTimer;

  AuthCubit({required AuthService authService})
      : _authService = authService,
        super(AuthState.initial());

  void setLoginMethod(LoginMethod method) {
    emit(state.copyWith(
      loginMethod: method,
      clearError: true,
    ));
  }

  void setIdentifier(String value) {
    final trimmed = value.trim();
    if (trimmed.contains('@')) {
      emit(state.copyWith(
        loginMethod: LoginMethod.email,
        email: trimmed,
        rawPhoneNumber: '',
        clearError: true,
      ));
    } else {
      var phone = trimmed;
      if (phone.startsWith('+966')) {
        phone = phone.substring(4);
      } else if (phone.startsWith('00966')) {
        phone = phone.substring(5);
      } else if (phone.startsWith('0') && phone.length > 9) {
        phone = phone.substring(1);
      }
      emit(state.copyWith(
        loginMethod: LoginMethod.phone,
        rawPhoneNumber: phone,
        email: trimmed,
        clearError: true,
      ));
    }
  }

  void setEmail(String email) {
    setIdentifier(email);
  }

  void setPassword(String password) {
    emit(state.copyWith(
      password: password,
      clearError: true,
    ));
  }

  void togglePasswordVisibility() {
    emit(state.copyWith(
      isPasswordVisible: !state.isPasswordVisible,
    ));
  }

  void setCountry(CountryCodeModel country) {
    emit(state.copyWith(
      selectedCountry: country,
      clearError: true,
    ));
  }

  void setPhoneNumber(String phone) {
    setIdentifier(phone);
  }

  void setOtpCode(String otp) {
    emit(state.copyWith(
      otpCode: otp,
      clearError: true,
    ));
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  /// Continues into the application as a guest user.
  void continueAsGuest() {
    _countdownTimer?.cancel();
    emit(state.copyWith(
      status: AuthStatus.guest,
      clearError: true,
    ));
  }

  /// Verifies if a stored valid session exists.
  Future<void> checkAuthStatus() async {
    try {
      final isAuth = await _authService.isAuthenticated();
      if (isAuth) {
        final session = await _authService.getCurrentSession();
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          roles: session?.roles ?? const [],
          userName: session?.name,
          userId: session?.userId,
          email: session?.email,
          rawPhoneNumber: session?.phoneNumber ?? '',
          isEmailVerified: session?.isEmailVerified ?? false,
          isAccountVerified: session?.isAccountVerified ?? false,
          clearError: true,
        ));

        try {
          if (singelton.isRegistered<RestaurantCubit>()) {
            singelton<RestaurantCubit>().loadRestaurant(session?.userId ?? session?.email);
          }
        } catch (_) {}
      }
    } catch (_) {
      // In case of storage read issue, remain in initial state
    }
  }

  /// Signs out the user, revokes session and resets cubit state.
  Future<void> logout() async {
    _countdownTimer?.cancel();
    try {
      await _authService.signOut();
    } catch (_) {}
    try {
      if (singelton.isRegistered<RestaurantCubit>()) {
        singelton<RestaurantCubit>().setHasRestaurant(false);
      }
    } catch (_) {}
    emit(AuthState.initial());
  }

  void editPhoneNumber() {
    _countdownTimer?.cancel();
    emit(state.copyWith(
      step: AuthStep.login,
      status: AuthStatus.idle,
      otpCode: '',
      clearError: true,
    ));
  }

  String _normalizePhone(String phone) {
    var p = phone.trim();
    if (p.startsWith('+')) {
      return p;
    }
    if (p.startsWith('00')) {
      return '+${p.substring(2)}';
    }
    if (p.startsWith('0')) {
      p = p.substring(1);
    }
    return '+966$p';
  }

  /// Sign in using unified identifier (Email OR Phone Number) + Password.
  /// Prevents duplicate concurrent requests.
  Future<void> submitLogin() async {
    if (state.isSubmitting) return;

    final id = state.email.trim();
    final password = state.password;

    if (id.isEmpty || password.isEmpty) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorCode: AuthErrorCode.invalidCredentials,
        errorMessage: 'Please enter both email and password.',
      ));
      return;
    }

    final isEmail = id.contains('@') || !RegExp(r'^[0-9+]+$').hasMatch(id);

    if (isEmail) {
      if (!state.isEmailValid || !state.isPasswordValid) {
        emit(state.copyWith(
          status: AuthStatus.error,
          errorCode: AuthErrorCode.invalidCredentials,
          errorMessage: 'Invalid email or password format',
        ));
        return;
      }

      emit(state.copyWith(
        status: AuthStatus.loading,
        clearError: true,
      ));

      try {
        final session = await _authService.loginWithEmailAndPassword(
          email: id,
          password: password,
        );

        emit(state.copyWith(
          status: AuthStatus.authenticated,
          roles: session.roles,
          userName: session.name,
          userId: session.userId,
          email: session.email ?? id,
          isEmailVerified: session.isEmailVerified,
          isAccountVerified: session.isAccountVerified,
          clearError: true,
        ));

        try {
          if (singelton.isRegistered<RestaurantCubit>()) {
            singelton<RestaurantCubit>().loadRestaurant(session.userId.isNotEmpty ? session.userId : (session.email ?? ''));
          }
        } catch (_) {}
      } on AuthException catch (e) {
        emit(state.copyWith(
          status: AuthStatus.error,
          errorCode: e.code,
          errorMessage: e.message,
        ));
      } catch (e) {
        emit(state.copyWith(
          status: AuthStatus.error,
          errorCode: AuthErrorCode.unknown,
          errorMessage: 'Something went wrong. Please try again later.',
        ));
      }
    } else {
      // Phone + Password
      final phone = state.rawPhoneNumber.isNotEmpty ? state.rawPhoneNumber : id;
      if (phone.length < 6 || !state.isPasswordValid) {
        emit(state.copyWith(
          status: AuthStatus.error,
          errorCode: AuthErrorCode.invalidCredentials,
          errorMessage: 'Invalid phone number or password format',
        ));
        return;
      }

      final normalized = _normalizePhone(phone);

      emit(state.copyWith(
        status: AuthStatus.loading,
        normalizedPhoneNumber: normalized,
        clearError: true,
      ));

      try {
        final session = await _authService.loginWithPhoneAndPassword(
          phoneNumber: normalized,
          password: password,
        );

        emit(state.copyWith(
          status: AuthStatus.authenticated,
          roles: session.roles,
          userName: session.name,
          userId: session.userId,
          email: session.email,
          rawPhoneNumber: session.phoneNumber,
          isEmailVerified: session.isEmailVerified,
          isAccountVerified: session.isAccountVerified,
          clearError: true,
        ));

        try {
          if (singelton.isRegistered<RestaurantCubit>()) {
            singelton<RestaurantCubit>().loadRestaurant(session.userId.isNotEmpty ? session.userId : (session.email ?? ''));
          }
        } catch (_) {}
      } on AuthException catch (e) {
        emit(state.copyWith(
          status: AuthStatus.error,
          errorCode: e.code,
          errorMessage: e.message,
        ));
      } catch (e) {
        emit(state.copyWith(
          status: AuthStatus.error,
          errorCode: AuthErrorCode.unknown,
          errorMessage: 'Something went wrong. Please try again later.',
        ));
      }
    }
  }

  /// Register a new restaurant owner account.
  Future<bool> register({
    required String name,
    required String email,
    required String phoneNumber,
    required String password,
    DateTime? birthDate,
    String? address,
    List<PhoneNumberItem>? phoneNumbers,
    RegistrationRole role = RegistrationRole.restaurant,
  }) async {
    if (state.isSubmitting) return false;

    final cleanName = name.trim();
    final cleanEmail = email.trim();
    final cleanPhone = phoneNumber.trim();

    if (cleanName.isEmpty) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorCode: AuthErrorCode.invalidCredentials,
        errorMessage: 'Name cannot be empty',
      ));
      return false;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(cleanEmail)) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorCode: AuthErrorCode.invalidCredentials,
        errorMessage: 'Invalid email format',
      ));
      return false;
    }

    if (password.length < 6) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorCode: AuthErrorCode.invalidCredentials,
        errorMessage: 'Password must be at least 6 characters',
      ));
      return false;
    }

    emit(state.copyWith(
      status: AuthStatus.loading,
      clearError: true,
    ));

    try {
      final session = await _authService.register(
        name: cleanName,
        email: cleanEmail,
        phoneNumber: cleanPhone,
        password: password,
        birthDate: birthDate,
        address: address,
        phoneNumbers: phoneNumbers,
        role: role,
      );

      emit(state.copyWith(
        status: AuthStatus.authenticated,
        email: cleanEmail,
        rawPhoneNumber: cleanPhone,
        roles: session.roles,
        userName: session.name ?? cleanName,
        userId: session.userId,
        isEmailVerified: session.isEmailVerified,
        isAccountVerified: session.isAccountVerified,
        clearError: true,
      ));
      return true;
    } on AuthException catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorCode: e.code,
        errorMessage: e.message,
      ));
      return false;
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorCode: AuthErrorCode.unknown,
        errorMessage: e.toString(),
      ));
      return false;
    }
  }

  /// Initiates sending OTP code to the normalized phone number.
  Future<void> sendOtp() async {
    if (state.isSubmitting) return;

    if (!state.isPhoneValid) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorCode: AuthErrorCode.invalidOtp,
        errorMessage: 'Invalid phone number format',
      ));
      return;
    }

    final normalized =
        state.selectedCountry.normalize(state.rawPhoneNumber);

    emit(state.copyWith(
      status: AuthStatus.sendingOtp,
      normalizedPhoneNumber: normalized,
      clearError: true,
    ));

    try {
      final response = await _authService.sendOtp(phoneNumber: normalized);

      emit(state.copyWith(
        step: AuthStep.otpVerification,
        status: AuthStatus.otpSent,
        verificationId: response.verificationId,
        codeLength: response.codeLength,
        resendCountdown: response.resendCooldownSeconds,
        otpCode: '',
        clearError: true,
      ));

      _startResendCountdown(response.resendCooldownSeconds);
    } on AuthException catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorCode: e.code,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorCode: AuthErrorCode.unknown,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Resends OTP to the current phone number if cooldown has elapsed.
  Future<void> resendOtp() async {
    if (state.isSubmitting || !state.canResend) return;
    if (state.normalizedPhoneNumber == null || state.verificationId == null) return;

    emit(state.copyWith(
      status: AuthStatus.sendingOtp,
      clearError: true,
    ));

    try {
      final response = await _authService.resendOtp(
        verificationId: state.verificationId!,
        phoneNumber: state.normalizedPhoneNumber!,
      );

      emit(state.copyWith(
        status: AuthStatus.otpSent,
        verificationId: response.verificationId,
        codeLength: response.codeLength,
        resendCountdown: response.resendCooldownSeconds,
        clearError: true,
      ));

      _startResendCountdown(response.resendCooldownSeconds);
    } on AuthException catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorCode: e.code,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorCode: AuthErrorCode.unknown,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Verifies OTP submitted by user.
  Future<void> verifyOtp() async {
    if (state.isSubmitting) return;

    if (state.otpCode.length != state.codeLength) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorCode: AuthErrorCode.invalidOtp,
        errorMessage: 'Incomplete OTP code',
      ));
      return;
    }

    if (state.verificationId == null || state.normalizedPhoneNumber == null) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorCode: AuthErrorCode.expiredOtp,
        errorMessage: 'Session expired. Please request a new code.',
      ));
      return;
    }

    emit(state.copyWith(
      status: AuthStatus.verifyingOtp,
      clearError: true,
    ));

    try {
      final result = await _authService.verifyOtp(
        verificationId: state.verificationId!,
        phoneNumber: state.normalizedPhoneNumber!,
        otpCode: state.otpCode,
      );

      if (result.isSuccess) {
        _countdownTimer?.cancel();
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          clearError: true,
        ));
      } else {
        emit(state.copyWith(
          status: AuthStatus.error,
          errorCode: result.errorCode ?? AuthErrorCode.invalidOtp,
          errorMessage: result.errorMessage,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorCode: AuthErrorCode.unknown,
        errorMessage: e.toString(),
      ));
    }
  }

  void _startResendCountdown(int seconds) {
    _countdownTimer?.cancel();
    emit(state.copyWith(resendCountdown: seconds));

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final current = state.resendCountdown;
      if (current <= 1) {
        timer.cancel();
        emit(state.copyWith(resendCountdown: 0));
      } else {
        emit(state.copyWith(resendCountdown: current - 1));
      }
    });
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    return super.close();
  }
}
