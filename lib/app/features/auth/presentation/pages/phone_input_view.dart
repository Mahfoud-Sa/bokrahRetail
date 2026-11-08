import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:bokrah_design_system/bokrah_design_system.dart';
import '../../../../config/l10n/app_localizations.dart';
import '../../../settings/presentation/cubits/settings_cubit.dart';
import '../../data/models/otp_response_model.dart';
import '../cubits/auth_cubit.dart';
import '../cubits/auth_state.dart';
import '../widgets/auth_button.dart';
import '../widgets/store_header.dart';
import '../widgets/terms_dialog.dart';

class PhoneInputView extends StatefulWidget {
  const PhoneInputView({super.key});

  @override
  State<PhoneInputView> createState() => _PhoneInputViewState();
}

class _PhoneInputViewState extends State<PhoneInputView> {
  late TextEditingController _identifierController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<AuthCubit>();
    final initialId = cubit.state.email.isNotEmpty
        ? cubit.state.email
        : cubit.state.rawPhoneNumber;
    _identifierController = TextEditingController(text: initialId);
    _passwordController = TextEditingController(text: cubit.state.password);
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showForgotPasswordDialog() {
    final isArabic =
        context.read<SettingsCubit>().state.locale.languageCode == 'ar';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BkRadius.md),
        ),
        title: Row(
          children: [
            Icon(
              Icons.lock_reset,
              color: Theme.of(context).colorScheme.primary,
              size: 26,
            ),
            const SizedBox(width: 10),
            Text(
              isArabic ? 'استعادة كلمة المرور' : 'Reset Password',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          isArabic
              ? 'يرجى مراجعة مسؤول النظام لإعادة تعيين بيانات الحساب المؤسسي.'
              : 'Please contact your enterprise system administrator to reset your account credentials.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isArabic ? 'إغلاق' : 'Close'),
          ),
        ],
      ),
    );
  }

  String _resolveErrorMessage(BuildContext context, AuthState state) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final msg = state.errorMessage ?? '';

    if (msg.contains('Please enter both email and password') ||
        msg.contains('Email is required') ||
        msg.contains('Password is required') ||
        msg.contains('Missing email or password')) {
      return isArabic
          ? 'يرجى إدخال البريد الإلكتروني وكلمة المرور.'
          : 'Please enter both email and password.';
    }

    if (msg.contains('Your account has been deactivated') ||
        msg.contains('User account is deactivated') ||
        msg.toLowerCase().contains('deactivated')) {
      return isArabic
          ? 'تم إلغاء تنشيط حسابك. يرجى التواصل مع الدعم الفني.'
          : 'Your account has been deactivated. Please contact support.';
    }

    if (msg.contains('No account found with this email address') ||
        msg.contains('User not found')) {
      return isArabic
          ? 'لا يوجد حساب مسجل بهذا البريد الإلكتروني.'
          : 'No account found with this email address.';
    }

    if (msg.contains('Invalid email or password') ||
        msg.contains('Invalid email or password format') ||
        state.errorCode == AuthErrorCode.invalidCredentials) {
      return isArabic
          ? 'بيانات الدخول غير صحيحة. يرجى المحاولة مرة أخرى.'
          : 'Invalid email or password. Please try again.';
    }

    if (msg.contains('Something went wrong') ||
        state.errorCode == AuthErrorCode.unknown) {
      return isArabic
          ? 'حدث خطأ ما. يرجى المحاولة مرة أخرى لاحقاً.'
          : 'Something went wrong. Please try again later.';
    }

    if (state.errorCode == AuthErrorCode.rateLimited) {
      final l10n = AppLocalizations.of(context);
      return l10n?.rateLimitError ??
          (isArabic
              ? 'تجاوزت الحد المسموح من المحاولات'
              : 'Too many attempts');
    }

    if (state.errorCode == AuthErrorCode.networkError) {
      final l10n = AppLocalizations.of(context);
      return l10n?.networkError ??
          (isArabic ? 'خطأ في الاتصال بالشبكة' : 'Network error');
    }

    return msg.isNotEmpty
        ? msg
        : (isArabic
            ? 'بيانات الدخول غير صحيحة. يرجى المحاولة مرة أخرى.'
            : 'Invalid email or password. Please try again.');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        final currentText = _identifierController.text;
        final expected = state.email.isNotEmpty
            ? state.email
            : state.rawPhoneNumber;
        if (expected.isNotEmpty && currentText != expected) {
          _identifierController.text = expected;
        }
        if (_passwordController.text != state.password) {
          _passwordController.text = state.password;
        }
      },
      builder: (context, state) {
        final cubit = context.read<AuthCubit>();
        final hasError =
            state.errorMessage != null && state.errorMessage!.isNotEmpty;

        final isEmailInput = _identifierController.text.contains('@');
        final isPhoneInput = !_identifierController.text.contains('@') &&
            _identifierController.text.trim().isNotEmpty;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Bokrah Header (Branding, Logo, Language Switcher, Theme Mode Switcher)
                  const StoreHeader(),

                  const SizedBox(height: 28),

                  // Credentials Form Card
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(BkRadius.lg),
                      border: Border.all(
                        color: hasError
                            ? theme.colorScheme.error
                            : theme.dividerColor.withValues(alpha: 0.2),
                        width: hasError ? 1.5 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Unified Identifier Field Label
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                isArabic
                                    ? 'البريد الإلكتروني أو رقم الهاتف'
                                    : 'Email or Phone Number',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (isEmailInput)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isArabic ? 'بريد' : 'Email',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              )
                            else if (isPhoneInput)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isArabic ? 'هاتف' : 'Phone',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Unified Identifier Input
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(BkRadius.md),
                            border: Border.all(
                              color: theme.dividerColor.withValues(alpha: 0.25),
                            ),
                          ),
                          child: TextField(
                            controller: _identifierController,
                            enabled: !state.isSubmitting,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                isEmailInput
                                    ? Icons.email_outlined
                                    : isPhoneInput
                                        ? Icons.phone_iphone_outlined
                                        : Icons.person_outline,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                              hintText: isArabic
                                  ? 'name@bokrah.com أو 050xxxxxxx'
                                  : 'name@bokrah.com or +96650xxxxxxx',
                              hintStyle: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.4),
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                            ),
                            onChanged: (val) => cubit.setIdentifier(val),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Password Field Label
                        Text(
                          isArabic ? 'كلمة المرور' : 'Password',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Password Input
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(BkRadius.md),
                            border: Border.all(
                              color: theme.dividerColor.withValues(alpha: 0.25),
                            ),
                          ),
                          child: TextField(
                            controller: _passwordController,
                            enabled: !state.isSubmitting,
                            obscureText: !state.isPasswordVisible,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  state.isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                  size: 20,
                                ),
                                onPressed: () =>
                                    cubit.togglePasswordVisibility(),
                              ),
                              hintText: isArabic
                                  ? 'أدخل كلمة المرور (٦ أحرف على الأقل)'
                                  : 'Enter password (min 6 characters)',
                              hintStyle: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.4),
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                            ),
                            onChanged: (val) => cubit.setPassword(val),
                            onSubmitted: (_) {
                              cubit.submitLogin();
                            },
                          ),
                        ),

                        // Forgot Password Link
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton(
                            onPressed: _showForgotPasswordDialog,
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 0,
                              ),
                            ),
                            child: Text(
                              isArabic
                                  ? 'نسيت كلمة المرور؟'
                                  : 'Forgot password?',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),

                        // Error message feedback
                        if (hasError) ...[
                          const SizedBox(height: 6),
                          Container(
                            key: const ValueKey('login_error_container'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(BkRadius.sm),
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
                                    _resolveErrorMessage(context, state),
                                    key: const ValueKey('login_error_text'),
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
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sign In Primary Button
                  AuthButton(
                    key: const ValueKey('login_submit_button'),
                    text: isArabic ? 'تسجيل الدخول' : 'Sign In',
                    icon: Icons.login_rounded,
                    isLoading: state.isSubmitting,
                    onPressed: state.isSubmitting
                        ? null
                        : () {
                            FocusScope.of(context).unfocus();
                            cubit.submitLogin();
                          },
                  ),
                  const SizedBox(height: 14),

                  // OR Separator
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: theme.dividerColor.withValues(alpha: 0.15),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          isArabic ? 'أو' : 'OR',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: theme.dividerColor.withValues(alpha: 0.15),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Continue as Guest Button
                  OutlinedButton(
                    key: const ValueKey('continue_as_guest_button'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      side: BorderSide(
                        color: theme.colorScheme.primary.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(BkRadius.md),
                      ),
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.04),
                    ),
                    onPressed: state.isSubmitting
                        ? null
                        : () {
                            FocusScope.of(context).unfocus();
                            cubit.continueAsGuest();
                          },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 19,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            isArabic ? 'المتابعة كضيف' : 'Continue as Guest',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Register Retail Store Link / Card
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
                          Icon(
                            Icons.storefront_outlined,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isArabic
                                ? 'ليس لديك حساب؟'
                                : "Don't have an account?",
                            style: TextStyle(
                              fontSize: 13.5,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(width: 6),
                          KeyedSubtree(
                            key: const ValueKey('register_restaurant_button'),
                            child: TextButton(
                              key: const ValueKey('register_retail_button'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                try {
                                  context.go('/register');
                                } catch (_) {}
                              },
                              child: Text(
                                isArabic
                                    ? 'أضف متجرك (ريتيل)'
                                    : 'Add your retail',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Terms of Service and Privacy Policy Link
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 12.5,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                          height: 1.45,
                        ),
                        children: [
                          TextSpan(
                            text: isArabic
                                ? 'بتسجيل الدخول، فإنك توافق على '
                                : 'By signing in, you agree to our ',
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
    );
  }
}
