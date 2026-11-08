import 'auth_session_model.dart';

/// Response received when requesting an OTP for a normalized phone number.
class SendOtpResponse {
  final String verificationId;
  final int codeLength;
  final int resendCooldownSeconds;
  final String normalizedPhone;
  final String? message;

  const SendOtpResponse({
    required this.verificationId,
    required this.codeLength,
    required this.resendCooldownSeconds,
    required this.normalizedPhone,
    this.message,
  });
}

/// Known error codes returned by OTP verification and submission APIs.
enum AuthErrorCode {
  invalidOtp,
  expiredOtp,
  rateLimited,
  networkError,
  invalidCredentials,
  unknown;

  static AuthErrorCode fromString(String? code) {
    switch (code) {
      case 'invalid_otp':
        return AuthErrorCode.invalidOtp;
      case 'expired_otp':
        return AuthErrorCode.expiredOtp;
      case 'rate_limited':
        return AuthErrorCode.rateLimited;
      case 'network_error':
        return AuthErrorCode.networkError;
      case 'invalid_credentials':
        return AuthErrorCode.invalidCredentials;
      default:
        return AuthErrorCode.unknown;
    }
  }
}

/// Result of verifying an OTP.
class VerifyOtpResponse {
  final bool isSuccess;
  final AuthSessionModel? session;
  final AuthErrorCode? errorCode;
  final String? errorMessage;

  const VerifyOtpResponse({
    required this.isSuccess,
    this.session,
    this.errorCode,
    this.errorMessage,
  });

  factory VerifyOtpResponse.success(AuthSessionModel session) =>
      VerifyOtpResponse(isSuccess: true, session: session);

  factory VerifyOtpResponse.failure(AuthErrorCode code, [String? message]) =>
      VerifyOtpResponse(
        isSuccess: false,
        errorCode: code,
        errorMessage: message,
      );
}
