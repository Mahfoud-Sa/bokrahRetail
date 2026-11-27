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
  String get manufacturerCompany => 'Manufacturer company *';

  @override
  String get selectManufacturerCompany =>
      'Please select a manufacturer company';

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
      'Welcome to Bokrah Retail! By using our store point-of-sale and inventory management platform, you agree to accurate transaction processing, compliance with our store policies, and respectful interaction with all customer service features.';

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

  @override
  String get unitsManagementTitle => 'Units of Measurement';

  @override
  String get addUnit => 'Add Unit';

  @override
  String get editUnit => 'Edit Unit';

  @override
  String get deleteUnit => 'Delete Unit';

  @override
  String get unitName => 'Unit Name *';

  @override
  String get unitNameHint => 'e.g. Piece, Box, Kg';

  @override
  String get unitNameRequired => 'Please enter a unit name';

  @override
  String get conversionFactor => 'Conversion Factor *';

  @override
  String get conversionFactorHint => '1.0 for base unit';

  @override
  String get conversionFactorInvalid => 'Please enter a number greater than 0';

  @override
  String get unitBarcodes => 'Barcodes (optional, comma-separated)';

  @override
  String get searchUnitsHint => 'Search units by name, factor, or barcode...';

  @override
  String get totalUnits => 'Total Units';

  @override
  String get baseUnits => 'Base Units';

  @override
  String get packagingUnits => 'Packaging Units';

  @override
  String get baseUnitBadge => 'Base Unit';

  @override
  String get factorPrefix => 'Factor:';

  @override
  String get barcodesCountLabel => 'barcodes';

  @override
  String get noUnitsTitle => 'No units of measurement yet';

  @override
  String get noUnitsSubtitle =>
      'Add units (e.g. Piece, Box, Kg) to organize packaging and conversions';

  @override
  String get noMatchingUnits => 'No matching units found';

  @override
  String get tryAnotherSearch => 'Try a different search term';

  @override
  String get confirmDeleteUnitTitle => 'Confirm Delete Unit';

  @override
  String get confirmDeleteUnitMessage =>
      'Are you sure you want to delete this unit?';

  @override
  String get unitSavedSuccess => 'Unit saved successfully';

  @override
  String get unitUpdatedSuccess => 'Unit updated successfully';

  @override
  String get unitDeletedSuccess => 'Unit deleted successfully';

  @override
  String get unitActionFailed => 'Operation failed. Please try again.';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get retry => 'Retry';

  @override
  String get departmentsManagementTitle => 'Departments Management';

  @override
  String get addDepartment => 'Add Department';

  @override
  String get addDepartmentTitle => 'Add New Department';

  @override
  String get editDepartment => 'Edit Department';

  @override
  String get deleteDepartment => 'Delete Department';

  @override
  String get departmentBasicInfo => 'Basic Information (Required)';

  @override
  String get departmentAdditionalDetails => 'Description & Additional Details';

  @override
  String get departmentName => 'Department Name *';

  @override
  String get departmentNameHint => 'e.g. Electronics, Clothing, Groceries';

  @override
  String get departmentNameRequired => 'Please enter a department name';

  @override
  String get departmentCode => 'Department Code (Optional)';

  @override
  String get departmentCodeHint => 'e.g. DEPT-ELEC or PHONE';

  @override
  String get departmentDescription => 'Department Description (Optional)';

  @override
  String get departmentDescriptionHint =>
      'Description of products and items in this department';

  @override
  String get searchDepartmentsHint => 'Search departments by name or code...';

  @override
  String get saveDepartment => 'Save Department';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get departmentAddedSuccess => 'Department added successfully';

  @override
  String get departmentUpdatedSuccess => 'Department updated successfully';

  @override
  String get departmentDeletedSuccess => 'Department deleted successfully';

  @override
  String get departmentSaveError => 'Error saving department';

  @override
  String get departmentDeleteError => 'Error deleting department';

  @override
  String get confirmDeleteDepartmentTitle => 'Confirm Delete Department';

  @override
  String get confirmDeleteDepartmentMessage =>
      'Are you sure you want to delete this department?';

  @override
  String get departmentItemsCountLabel => 'items';

  @override
  String get noDepartmentsTitle => 'No departments registered yet';

  @override
  String get noDepartmentsSubtitle =>
      'Create departments to classify and organize items accurately';

  @override
  String get noMatchingDepartments => 'No matching departments found';

  @override
  String get viewDepartmentItems => 'View Items';

  @override
  String get addItemInDepartment => 'Add Item in Department';

  @override
  String get totalDepartments => 'Total Departments';

  @override
  String get linkedItemsCount => 'Linked Items';
}
