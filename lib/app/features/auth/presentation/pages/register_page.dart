import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bokrah_design_system/bokrah_design_system.dart';
import '../../../../config/l10n/app_localizations.dart';
import '../../../../initialzation_dependencies.dart';
import '../../data/datasources/auth_token_storage.dart';
import '../../data/models/auth_dto.dart';
import '../../data/models/country_code_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/mock_auth_service.dart';
import '../cubits/auth_cubit.dart';
import '../cubits/auth_state.dart';
import '../widgets/auth_button.dart';
import '../widgets/country_code_picker_dialog.dart';
import '../widgets/store_header.dart';
import '../widgets/terms_dialog.dart';
import '../../../store/data/services/store_service.dart';

/// Store Registration Page - Step 1: Create Owner Account
///
/// Collects owner credentials (name, email, phone, password), authenticates
/// the owner, and seamlessly transitions to Step 2 (/store-info)
/// to configure store details and settings.
class RegisterPage extends StatelessWidget {
  final AuthService? authService;

  const RegisterPage({super.key, this.authService});

  @override
  Widget build(BuildContext context) {
    AuthCubit? existingCubit;
    try {
      existingCubit = context.read<AuthCubit>();
    } catch (_) {}

    if (authService == null && existingCubit != null) {
      return const _RegisterPageContent();
    }

    return FutureBuilder<AuthService>(
      future: _resolveAuthService(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }

        return BlocProvider(
          create: (_) => AuthCubit(authService: snapshot.data!),
          child: const _RegisterPageContent(),
        );
      },
    );
  }

  Future<AuthService> _resolveAuthService() async {
    if (authService != null) return authService!;
    if (singelton.isRegistered<AuthService>()) {
      return singelton<AuthService>();
    }
    final prefs = await SharedPreferences.getInstance();
    final storage = SharedPrefsAuthTokenStorage(prefs: prefs);
    final mockService = MockAuthService(tokenStorage: storage);
    singelton.registerSingleton<AuthTokenStorage>(storage);
    singelton.registerSingleton<AuthService>(mockService);
    return mockService;
  }
}

class _RegisterPageContent extends StatefulWidget {
  const _RegisterPageContent();

  @override
  State<_RegisterPageContent> createState() => _RegisterPageContentState();
}

class _RegisterPageContentState extends State<_RegisterPageContent> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late final TextEditingController _addressController;

  DateTime _birthDate = DateTime(1995, 5, 15);
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _proceedToStoreInfo = true;
  CountryCodeModel _selectedCountry = CountryCodeModel.defaultCountry;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  void _onCountryTap() async {
    final country = await CountryCodePickerDialog.show(
      context,
      selectedCountry: _selectedCountry,
    );
    if (country != null && mounted) {
      setState(() {
        _selectedCountry = country;
      });
    }
  }

  String _formatErrorMessage(String message, bool isArabic) {
    if (message.contains('Email already exists')) {
      return isArabic
          ? 'البريد الإلكتروني مستخدم بالفعل. يرجى استخدام بريد آخر أو تسجيل الدخول.'
          : 'Email already exists.';
    }
    if (message.contains('A store with the same name already exists')) {
      return isArabic
          ? 'يوجد متجر مسجل بهذا الاسم بالفعل. يرجى اختيار اسم آخر.'
          : 'A store with the same name already exists.';
    }
    return message;
  }

  Future<void> _handleRegister({bool proceedToStoreInfo = true}) async {
    _proceedToStoreInfo = proceedToStoreInfo;
    setState(() {
      _localError = null;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    if (name.isEmpty) {
      setState(() {
        _localError = isArabic ? 'يرجى إدخال الاسم الكامل' : 'Please enter full name';
      });
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() {
        _localError = isArabic
            ? 'يرجى إدخال بريد إلكتروني صحيح'
            : 'Please enter a valid email address';
      });
      return;
    }

    if (phone.isEmpty) {
      setState(() {
        _localError = isArabic ? 'يرجى إدخال رقم الهاتف' : 'Please enter phone number';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _localError = isArabic
            ? 'كلمة المرور يجب أن لا تقل عن 6 أحرف'
            : 'Password must be at least 6 characters';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _localError = isArabic
            ? 'كلمتا المرور غير متطابقتين'
            : 'Passwords do not match';
      });
      return;
    }

    final fullPhone = _selectedCountry.normalize(phone);
    final addressText = _addressController.text.trim();

    final success = await context.read<AuthCubit>().register(
          name: name,
          email: email,
          phoneNumber: fullPhone,
          password: password,
          birthDate: _birthDate,
          address: addressText.isNotEmpty ? addressText : null,
          phoneNumbers: [
            PhoneNumberItem(number: fullPhone, type: 'Mobile'),
          ],
          role: RegistrationRole.store,
        );

    if (success && mounted) {
      try {
        StoreService storeService;
        if (singelton.isRegistered<StoreService>()) {
          storeService = singelton<StoreService>();
        } else {
          storeService = StoreService();
        }
        final existingStore = await storeService.getStoreInfo();
        await storeService.updateStoreInfo(
          existingStore.copyWith(
            nameAr: name,
            nameEn: name,
            email: email,
            phoneNumber: fullPhone,
            mobileNumber: fullPhone,
            shortAddress: addressText.isNotEmpty ? addressText : existingStore.shortAddress,
            street: addressText.isNotEmpty ? addressText : existingStore.street,
          ),
        );
      } catch (_) {}

      if (mounted) {
        try {
          if (_proceedToStoreInfo) {
            context.go('/store-info');
          } else {
            context.go('/store/dashboard');
          }
        } catch (_) {
          // Fallback in tests outside GoRouter
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          setState(() {
            _localError = state.errorMessage;
          });
        }
        if (state.status == AuthStatus.authenticated) {
          try {
            if (_proceedToStoreInfo) {
              context.go('/store-info');
            } else {
              context.go('/store/dashboard');
            }
          } catch (_) {
            // Fallback in tests outside GoRouter
          }
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 640;
                final cardMaxWidth = isWide ? 760.0 : 480.0;
                final horizontalPadding = isWide ? 32.0 : 20.0;

                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: cardMaxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header
                          StoreHeader(
                            title: isArabic
                                ? 'تسجيل متجر جديد'
                                : 'Register New Store',
                            subtitle: isArabic
                                ? 'أنشئ حساب المالك أولاً، ثم استكمل بيانات متجرك'
                                : 'Create owner account first, then setup your store details',
                          ),
                          const SizedBox(height: 20),

                          // Two-Step Progress Card (Responsive Grid layout)
                          _buildProgressCard(
                            theme: theme,
                            isArabic: isArabic,
                            isWide: isWide,
                          ),
                          const SizedBox(height: 20),

                          // Registration Form Card
                          Form(
                            key: _formKey,
                            child: Container(
                              padding: EdgeInsets.all(isWide ? 26 : 20),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(BkRadius.lg),
                                border: Border.all(
                                  color: theme.dividerColor.withValues(alpha: 0.15),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Grid Row 1: Full Name & Date of Birth
                                  _buildGridRow(
                                    isWide: isWide,
                                    first: _buildFieldGroup(
                                      label: isArabic ? 'الاسم الكامل' : 'Full Name',
                                      theme: theme,
                                      child: _buildInputField(
                                        context: context,
                                        controller: _nameController,
                                        hintText: isArabic
                                            ? 'أدخل اسمك الكريم'
                                            : 'e.g. John Doe',
                                        icon: Icons.person_outline,
                                        enabled: !state.isSubmitting,
                                        textInputAction: TextInputAction.next,
                                      ),
                                    ),
                                    second: _buildFieldGroup(
                                      label: isArabic ? 'تاريخ الميلاد' : 'Date of Birth',
                                      theme: theme,
                                      child: _buildBirthDateField(
                                        context: context,
                                        isSubmitting: state.isSubmitting,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Grid Row 2: Email & Phone Number
                                  _buildGridRow(
                                    isWide: isWide,
                                    first: _buildFieldGroup(
                                      label: isArabic ? 'البريد الإلكتروني' : 'Email Address',
                                      theme: theme,
                                      child: _buildInputField(
                                        context: context,
                                        controller: _emailController,
                                        hintText: isArabic
                                            ? 'owner@bokrah.com'
                                            : 'owner@bokrah.com',
                                        icon: Icons.email_outlined,
                                        keyboardType: TextInputType.emailAddress,
                                        enabled: !state.isSubmitting,
                                        textInputAction: TextInputAction.next,
                                      ),
                                    ),
                                    second: _buildFieldGroup(
                                      label: isArabic ? 'رقم الهاتف' : 'Phone Number',
                                      theme: theme,
                                      child: _buildPhoneField(
                                        context: context,
                                        isSubmitting: state.isSubmitting,
                                        isArabic: isArabic,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Row 3: Address (Full Width in Grid)
                                  _buildFieldGroup(
                                    label: isArabic
                                        ? 'العنوان (اختياري)'
                                        : 'Address (Optional)',
                                    theme: theme,
                                    child: _buildInputField(
                                      context: context,
                                      controller: _addressController,
                                      hintText: isArabic
                                          ? 'الشارع الرئيسي، وسط المدينة'
                                          : 'Main Street, City Center',
                                      icon: Icons.location_on_outlined,
                                      enabled: !state.isSubmitting,
                                      textInputAction: TextInputAction.next,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Grid Row 4: Password & Confirm Password
                                  _buildGridRow(
                                    isWide: isWide,
                                    first: _buildFieldGroup(
                                      label: isArabic ? 'كلمة المرور' : 'Password',
                                      theme: theme,
                                      child: _buildInputField(
                                        context: context,
                                        controller: _passwordController,
                                        hintText: isArabic
                                            ? '6 أحرف على الأقل'
                                            : 'At least 6 characters',
                                        icon: Icons.lock_outline,
                                        obscureText: !_isPasswordVisible,
                                        enabled: !state.isSubmitting,
                                        textInputAction: TextInputAction.next,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _isPasswordVisible
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            size: 20,
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.5),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _isPasswordVisible =
                                                  !_isPasswordVisible;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    second: _buildFieldGroup(
                                      label: isArabic
                                          ? 'تأكيد كلمة المرور'
                                          : 'Confirm Password',
                                      theme: theme,
                                      child: _buildInputField(
                                        context: context,
                                        controller: _confirmPasswordController,
                                        hintText: isArabic
                                            ? 'أعد إدخال كلمة المرور'
                                            : 'Re-enter your password',
                                        icon: Icons.lock_reset_outlined,
                                        obscureText: !_isConfirmPasswordVisible,
                                        enabled: !state.isSubmitting,
                                        textInputAction: TextInputAction.done,
                                        onSubmitted: (_) => _handleRegister(),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _isConfirmPasswordVisible
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            size: 20,
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.5),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _isConfirmPasswordVisible =
                                                  !_isConfirmPasswordVisible;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Error Message Alert
                                  if (_localError != null) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.errorContainer,
                                        borderRadius:
                                            BorderRadius.circular(BkRadius.sm),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: theme.colorScheme.error,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _formatErrorMessage(_localError!, isArabic),
                                              key: const ValueKey('register_error_text'),
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: theme.colorScheme.error,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 24),

                                  // Primary Button: Register & Proceed to Step 2 (Optional)
                                  AuthButton(
                                    text: isArabic
                                        ? 'إنشاء الحساب ومتابعة إعداد المتجر (الخطوة 2)'
                                        : 'Create Account & Setup Store (Step 2)',
                                    icon: isArabic
                                        ? Icons.arrow_back_rounded
                                        : Icons.arrow_forward_rounded,
                                    isLoading: state.isSubmitting && _proceedToStoreInfo,
                                    onPressed: state.isSubmitting
                                        ? null
                                        : () {
                                            FocusScope.of(context).unfocus();
                                            _handleRegister(proceedToStoreInfo: true);
                                          },
                                  ),
                                  const SizedBox(height: 12),

                                  // Secondary Action: Skip Step 2 & Go directly to Dashboard
                                  OutlinedButton.icon(
                                    key: const ValueKey('skip_store_setup_button'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                        horizontal: 16,
                                      ),
                                      side: BorderSide(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.35),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(BkRadius.md),
                                      ),
                                    ),
                                    icon: state.isSubmitting && !_proceedToStoreInfo
                                        ? SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: theme.colorScheme.primary,
                                            ),
                                          )
                                        : Icon(
                                            Icons.dashboard_outlined,
                                            size: 18,
                                            color: theme.colorScheme.primary,
                                          ),
                                    label: Text(
                                      isArabic
                                          ? 'إنشاء الحساب والتخطي إلى لوحة التحكم (إكمال لاحقاً)'
                                          : 'Create Account & Skip to Dashboard (Complete Later)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    onPressed: state.isSubmitting
                                        ? null
                                        : () {
                                            FocusScope.of(context).unfocus();
                                            _handleRegister(proceedToStoreInfo: false);
                                          },
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    isArabic
                                        ? 'الخطوة 2 اختيارية تماماً، ويمكنك ملء بيانات المتجر والضرائب في أي وقت من الإعدادات.'
                                        : 'Step 2 is completely optional. You can configure commercial register & taxes anytime from Settings.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Already have an account? Sign In Link
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(BkRadius.md),
                              border: Border.all(
                                color: theme.dividerColor.withValues(alpha: 0.15),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isArabic
                                        ? 'لديك حساب بالفعل؟'
                                        : 'Already have an account?',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () {
                                      try {
                                        context.go('/login');
                                      } catch (_) {}
                                    },
                                    child: Text(
                                      isArabic ? 'تسجيل الدخول' : 'Sign In',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Terms and Privacy
                          Center(
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                  height: 1.45,
                                ),
                                children: [
                                  TextSpan(
                                    text: isArabic
                                        ? 'بالتسجيل، فإنك توافق على '
                                        : 'By registering, you agree to our ',
                                  ),
                                  TextSpan(
                                    text: isArabic
                                        ? 'شروط الخدمة'
                                        : l10n.termsOfService,
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => TermsDialog.show(
                                            context,
                                            isPrivacy: false,
                                          ),
                                  ),
                                  TextSpan(text: isArabic ? ' و ' : ' and '),
                                  TextSpan(
                                    text: isArabic
                                        ? 'سياسة الخصوصية'
                                        : l10n.privacyPolicy,
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => TermsDialog.show(
                                            context,
                                            isPrivacy: true,
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridRow({
    required bool isWide,
    required Widget first,
    required Widget second,
    double gap = 16,
  }) {
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: first),
          SizedBox(width: gap),
          Expanded(child: second),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        first,
        SizedBox(height: gap),
        second,
      ],
    );
  }

  Widget _buildFieldGroup({
    required String label,
    required ThemeData theme,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _buildBirthDateField({
    required BuildContext context,
    required bool isSubmitting,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: isSubmitting ? null : _pickBirthDate,
      borderRadius: BorderRadius.circular(BkRadius.md),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(BkRadius.md),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                DateFormat('yyyy-MM-dd').format(_birthDate),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneField({
    required BuildContext context,
    required bool isSubmitting,
    required bool isArabic,
  }) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(BkRadius.md),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          // Country selector button
          InkWell(
            onTap: isSubmitting ? null : _onCountryTap,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(BkRadius.md),
              left: Radius.circular(BkRadius.md),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 12,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedCountry.flagEmoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _selectedCountry.dialCode,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: theme.dividerColor.withValues(alpha: 0.2),
          ),
          Expanded(
            child: TextField(
              controller: _phoneController,
              enabled: !isSubmitting,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: isArabic ? '50xxxxxxx' : '50xxxxxxx',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard({
    required ThemeData theme,
    required bool isArabic,
    required bool isWide,
  }) {
    if (isWide) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(BkRadius.md),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            // Step 1: Required
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isArabic ? 'الخطوة 1 (إلزامية)' : 'Step 1 (Required)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                isArabic
                    ? 'إنشاء حساب المالك'
                    : 'Create Owner Account',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              width: 1,
              height: 24,
              color: theme.colorScheme.primary.withValues(alpha: 0.25),
              margin: const EdgeInsets.symmetric(horizontal: 12),
            ),
            // Step 2: Optional
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                isArabic ? 'الخطوة 2 (اختيارية)' : 'Step 2 (Optional)',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                isArabic
                    ? 'إعداد بيانات المتجر (يمكن إكمالها بأي وقت)'
                    : 'Store profile & settings (complete anytime)',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(BkRadius.md),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isArabic ? 'الخطوة 1 (إلزامية)' : 'Step 1 (Required)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isArabic
                      ? 'إنشاء حساب مالك المتجر'
                      : 'Create Store Owner Account',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  isArabic ? 'الخطوة 2 (اختيارية)' : 'Step 2 (Optional)',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isArabic
                      ? 'إعداد بيانات المتجر (يمكن إكمالها بأي وقت)'
                      : 'Store profile & settings (complete anytime)',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required BuildContext context,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    ValueChanged<String>? onSubmitted,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(BkRadius.md),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.25),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        enabled: enabled,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          suffixIcon: suffixIcon,
          hintText: hintText,
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
