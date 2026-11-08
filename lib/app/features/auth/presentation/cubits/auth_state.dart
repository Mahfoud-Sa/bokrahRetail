// ignore_for_file: deprecated_member_use

import 'package:equatable/equatable.dart';
import '../../data/models/country_code_model.dart';
import '../../data/models/otp_response_model.dart';

enum LoginMethod {
  email,
  phone,
}

enum AuthStep {
  login,
  otpVerification,
}

enum AuthStatus {
  idle,
  loading,
  sendingOtp,
  otpSent,
  verifyingOtp,
  authenticated,
  guest,
  error,
}

class AuthState extends Equatable {
  final AuthStep step;
  final AuthStatus status;
  final LoginMethod loginMethod;
  final String email;
  final String password;
  final bool isPasswordVisible;
  final CountryCodeModel selectedCountry;
  final String rawPhoneNumber;
  final String? normalizedPhoneNumber;
  final String? verificationId;
  final String otpCode;
  final int codeLength;
  final int resendCountdown;
  final String? errorMessage;
  final AuthErrorCode? errorCode;
  final String? userName;
  final String? userId;
  final List<String> roles;
  final bool isEmailVerified;
  final bool isAccountVerified;

  const AuthState({
    this.step = AuthStep.login,
    this.status = AuthStatus.idle,
    this.loginMethod = LoginMethod.email,
    this.email = '',
    this.password = '',
    this.isPasswordVisible = false,
    required this.selectedCountry,
    this.rawPhoneNumber = '',
    this.normalizedPhoneNumber,
    this.verificationId,
    this.otpCode = '',
    this.codeLength = 6,
    this.resendCountdown = 0,
    this.errorMessage,
    this.errorCode,
    this.userName,
    this.userId,
    this.roles = const [],
    this.isEmailVerified = false,
    this.isAccountVerified = false,
  });

  factory AuthState.initial() => AuthState(
        selectedCountry: CountryCodeModel.defaultCountry,
      );

  bool get isSubmitting =>
      status == AuthStatus.loading ||
      status == AuthStatus.sendingOtp ||
      status == AuthStatus.verifyingOtp;

  bool get isGuest => status == AuthStatus.guest;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  bool get isRestaurant =>
      roles.any((r) => r.toLowerCase() == 'restaurant');

  bool get isEmailValid =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim());

  bool get isPasswordValid => password.length >= 6;

  bool get isPhoneValid => selectedCountry.isValid(rawPhoneNumber);

  bool get canSubmitLogin {
    if (isSubmitting) {
      return false;
    }
    final id = email.trim();
    if (id.isEmpty && rawPhoneNumber.isEmpty) {
      return false;
    }
    if (id.contains('@')) {
      return isEmailValid && isPasswordValid;
    } else {
      final phone = rawPhoneNumber.isNotEmpty ? rawPhoneNumber : id;
      return phone.length >= 6 && isPasswordValid;
    }
  }

  bool get canSubmitPhone => isPhoneValid && !isSubmitting;

  bool get canSubmitOtp => otpCode.length == codeLength && !isSubmitting;

  bool get canResend => resendCountdown == 0 && !isSubmitting;

  AuthState copyWith({
    AuthStep? step,
    AuthStatus? status,
    LoginMethod? loginMethod,
    String? email,
    String? password,
    bool? isPasswordVisible,
    CountryCodeModel? selectedCountry,
    String? rawPhoneNumber,
    String? normalizedPhoneNumber,
    String? verificationId,
    String? otpCode,
    int? codeLength,
    int? resendCountdown,
    String? errorMessage,
    AuthErrorCode? errorCode,
    String? userName,
    String? userId,
    List<String>? roles,
    bool? isEmailVerified,
    bool? isAccountVerified,
    bool clearError = false,
  }) {
    return AuthState(
      step: step ?? this.step,
      status: status ?? this.status,
      loginMethod: loginMethod ?? this.loginMethod,
      email: email ?? this.email,
      password: password ?? this.password,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      selectedCountry: selectedCountry ?? this.selectedCountry,
      rawPhoneNumber: rawPhoneNumber ?? this.rawPhoneNumber,
      normalizedPhoneNumber:
          normalizedPhoneNumber ?? this.normalizedPhoneNumber,
      verificationId: verificationId ?? this.verificationId,
      otpCode: otpCode ?? this.otpCode,
      codeLength: codeLength ?? this.codeLength,
      resendCountdown: resendCountdown ?? this.resendCountdown,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      userName: userName ?? this.userName,
      userId: userId ?? this.userId,
      roles: roles ?? this.roles,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isAccountVerified: isAccountVerified ?? this.isAccountVerified,
    );
  }

  @override
  List<Object?> get props => [
        step,
        status,
        loginMethod,
        email,
        password,
        isPasswordVisible,
        selectedCountry,
        rawPhoneNumber,
        normalizedPhoneNumber,
        verificationId,
        otpCode,
        codeLength,
        resendCountdown,
        errorMessage,
        errorCode,
        userName,
        userId,
        roles,
        isEmailVerified,
        isAccountVerified,
      ];
}
