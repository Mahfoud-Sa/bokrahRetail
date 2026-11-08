// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Bokrah';

  @override
  String get items => 'Items';

  @override
  String get units => 'Units';

  @override
  String get categories => 'Categories';

  @override
  String get warehouses => 'Warehouses';

  @override
  String get users => 'Users';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get dark => 'Dark';

  @override
  String get light => 'Light';

  @override
  String get system => 'System';

  @override
  String get welcomeHeading => 'Welcome! Hungry for something delicious?';

  @override
  String get welcomeSupporting => 'Sign in to order your favorite meals.';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get phoneHint => '50 123 4567';

  @override
  String get countryCode => 'Country';

  @override
  String get searchCountry => 'Search country or code...';

  @override
  String get sendVerificationCode => 'Send verification code';

  @override
  String get termsAndPrivacyPrefix => 'By continuing, you agree to our ';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get and => ' and ';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get invalidPhoneNumber => 'Please enter a valid phone number';

  @override
  String get verificationTitle => 'Verification Code';

  @override
  String get verificationSubtitle => 'We have sent a one-time code to';

  @override
  String get editPhone => 'Edit';

  @override
  String get verifyAndSignIn => 'Verify & sign in';

  @override
  String get didntReceiveCode => "Didn't receive the code?";

  @override
  String get resendCode => 'Resend code';

  @override
  String get resendInSeconds => 'Resend code in';

  @override
  String get invalidOtpError => 'Invalid verification code. Please try again.';

  @override
  String get expiredOtpError => 'Verification code has expired. Please request a new one.';

  @override
  String get rateLimitError => 'Too many attempts. Please wait before trying again.';

  @override
  String get networkError => 'Network error. Please check your connection.';

  @override
  String get enterCompleteCode => 'Please enter the complete verification code';

  @override
  String get termsOfServiceTitle => 'Terms of Service';

  @override
  String get termsOfServiceContent =>
      'Welcome to Bokrah Restaurant! By using our ordering app, you agree to accurate order placement, verified delivery information, and respectful customer service.';

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String get privacyPolicyContent =>
      'We value your privacy. Your phone number is strictly used for authentication and real-time delivery status notifications.';

  @override
  String get close => 'Close';

  @override
  String get switchLanguage => 'العربية';

  @override
  String get testCredentialsHint =>
      'Demo Mode: Use code 123456 to sign in. Test codes: 000000 (invalid), 111111 (expired).';

  @override
  String get signIn => 'Sign In';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get invalidEmail => 'Please enter a valid email address';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get forgotPasswordNotice =>
      'If an account exists, instructions have been sent.';

  @override
  String get invalidCredentialsError =>
      'Invalid credentials. Please verify your details.';

  @override
  String get signInWithEmail => 'Email';

  @override
  String get signInWithPhone => 'Phone Number';

  @override
  String get demoCredentialsNote =>
      'Demo: Any valid email/phone with password (min 6 chars) will succeed.';
}
