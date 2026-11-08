// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/l10n/app_localizations.dart';
import '../../../../config/theme.dart';
import '../../data/models/otp_response_model.dart';
import '../cubits/auth_cubit.dart';
import '../cubits/auth_state.dart';
import '../widgets/auth_button.dart';
import '../widgets/otp_input_field.dart';

class OtpVerificationView extends StatelessWidget {
  const OtpVerificationView({super.key});

  String _formatTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final minStr = minutes.toString().padLeft(2, '0');
    final secStr = seconds.toString().padLeft(2, '0');
    return '$minStr:$secStr';
  }

  String _resolveErrorMessage(BuildContext context, AuthState state) {
    final l10n = AppLocalizations.of(context)!;
    switch (state.errorCode) {
      case AuthErrorCode.invalidOtp:
        return l10n.invalidOtpError;
      case AuthErrorCode.expiredOtp:
        return l10n.expiredOtpError;
      case AuthErrorCode.rateLimited:
        return l10n.rateLimitError;
      case AuthErrorCode.networkError:
        return l10n.networkError;
      default:
        return state.errorMessage ?? l10n.invalidOtpError;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final cubit = context.read<AuthCubit>();
        final hasError =
            state.errorMessage != null && state.errorMessage!.isNotEmpty;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),

                  // Back / Edit phone button
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: state.isSubmitting
                          ? null
                          : () {
                              cubit.editPhoneNumber();
                            },
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textMediumBrown,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      icon: const Icon(Icons.arrow_back_ios, size: 16),
                      label: Text(
                        l10n.editPhone,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Verification Badge Icon
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.deepOrangeLight,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: AppTheme.shadowWarm,
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.mark_email_read_outlined,
                          size: 40,
                          color: AppTheme.deepOrange,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Heading
                  Text(
                    l10n.verificationTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDarkBrown,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Subtitle
                  Text(
                    l10n.verificationSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.textMediumBrown,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Phone number chip with quick edit pencil
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.creamInputFill,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.borderWarm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              state.normalizedPhoneNumber ??
                                  state.rawPhoneNumber,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDarkBrown,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: state.isSubmitting
                                ? null
                                : () => cubit.editPhoneNumber(),
                            child: const Padding(
                              padding: EdgeInsets.all(2.0),
                              child: Icon(
                                Icons.edit,
                                size: 16,
                                color: AppTheme.deepOrange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // OTP Entry Card
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.creamSurface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                      border: Border.all(
                        color:
                            hasError ? AppTheme.errorRed : AppTheme.borderWarm,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: AppTheme.shadowWarm,
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    child: Column(
                      children: [
                        // OTP Input with paste and autofill support
                        OtpInputField(
                          length: state.codeLength,
                          value: state.otpCode,
                          hasError: hasError,
                          enabled: !state.isSubmitting,
                          onChanged: (code) {
                            cubit.setOtpCode(code);
                          },
                          onCompleted: (code) {
                            cubit.verifyOtp();
                          },
                        ),

                        // Error message feedback
                        if (hasError) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.errorBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.errorRed.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: AppTheme.errorRed,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _resolveErrorMessage(context, state),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.errorRed,
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

                  // Verify & Sign In Button
                  AuthButton(
                    text: l10n.verifyAndSignIn,
                    icon: Icons.check_circle_outline,
                    isLoading: state.isSubmitting,
                    onPressed: state.canSubmitOtp
                        ? () {
                            FocusScope.of(context).unfocus();
                            cubit.verifyOtp();
                          }
                        : null,
                  ),

                  const SizedBox(height: 24),

                  // Resend Code Section
                  Center(
                    child: state.resendCountdown > 0
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                size: 16,
                                color: AppTheme.textMediumBrown,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${l10n.resendInSeconds} ${_formatTimer(state.resendCountdown)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textMediumBrown,
                                ),
                              ),
                            ],
                          )
                        : TextButton(
                            onPressed: state.isSubmitting
                                ? null
                                : () => cubit.resendOtp(),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.deepOrange,
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: Text(l10n.resendCode),
                          ),
                  ),

                  const SizedBox(height: 24),

                  // Test Hints Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.creamInputFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderWarm),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          size: 18,
                          color: AppTheme.deepOrange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.testCredentialsHint,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMediumBrown,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
