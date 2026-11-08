import '../models/auth_dto.dart';
import '../models/auth_session_model.dart';
import '../models/otp_response_model.dart';

/// Abstract service interface defining the Restaurant Authentication API.
/// UI and Cubits depend exclusively on this abstraction.
abstract class AuthService {
  /// Authenticate using email and password.
  Future<AuthSessionModel> loginWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Authenticate using normalized phone number and password.
  Future<AuthSessionModel> loginWithPhoneAndPassword({
    required String phoneNumber,
    required String password,
  });

  /// Register a new account (defaults to Restaurant registration).
  Future<AuthSessionModel> register({
    required String name,
    required String email,
    required String phoneNumber,
    required String password,
    DateTime? birthDate,
    String? address,
    List<PhoneNumberItem>? phoneNumbers,
    RegistrationRole role = RegistrationRole.restaurant,
  });

  /// Request a one-time verification code for the given normalized phone number.
  /// Returns [SendOtpResponse] with verificationId, dynamic codeLength, and resend cooldown.
  Future<SendOtpResponse> sendOtp({required String phoneNumber});

  /// Submit the verification code against the given [verificationId] and [phoneNumber].
  Future<VerifyOtpResponse> verifyOtp({
    required String verificationId,
    required String phoneNumber,
    required String otpCode,
  });

  /// Request a new OTP code for an active verification session.
  Future<SendOtpResponse> resendOtp({
    required String verificationId,
    required String phoneNumber,
  });

  /// Log out the currently authenticated user and revoke active tokens.
  Future<void> signOut();

  /// Check whether an authenticated session currently exists.
  Future<bool> isAuthenticated();

  /// Retrieve the current JWT access token for authenticated API requests.
  Future<String?> getAccessToken();

  /// Retrieve the current stored authenticated session.
  Future<AuthSessionModel?> getCurrentSession();

  /// Retrieve headers containing `Authorization: Bearer <token>` for authenticated requests.
  Future<Map<String, String>> getAuthHeaders();
}
