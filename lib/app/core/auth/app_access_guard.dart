import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:bokrah_design_system/bokrah_design_system.dart';
import '../../features/auth/presentation/cubits/auth_cubit.dart';
import '../../features/auth/presentation/cubits/auth_state.dart';
import '../../features/store/presentation/cubits/store_cubit.dart';
import '../../features/store/presentation/cubits/store_state.dart';
import '../../features/settings/presentation/cubits/settings_cubit.dart';

/// The three distinct user states supported across the application.
enum AppUserState {
  /// Unauthenticated guest user exploring the platform in read-only mode.
  guest,

  /// Authenticated user who has not yet registered/added their store profile.
  authenticatedWithoutRestaurant,

  /// Authenticated user who has successfully registered their store.
  authenticatedWithRestaurant;

  // Modern domain aliases
  static const AppUserState authenticatedWithoutStore = authenticatedWithoutRestaurant;
  static const AppUserState authenticatedWithStore = authenticatedWithRestaurant;
}

/// Centralized Access Control and Restriction Enforcement Guard.
class AppAccessGuard {
  /// Standardized User-Facing Messages
  static const String guestRestrictionMessageEn =
      'Please log in or create an account to use this feature.';
  static const String guestRestrictionMessageAr =
      'يُرجى تسجيل الدخول أو إنشاء حساب لاستخدام هذه الميزة.';

  static const String storeNoticeMessageEn =
      'Complete your account setup by adding your store details to enter all your business data and use retail and sales features.';
  static const String storeNoticeMessageAr =
      'أكمل إعداد حسابك بإضافة بيانات متجرك لإدخال جميع بيانات أعمالك واستخدام ميزات إدارة المبيعات والتجزئة.';

  static const String storeNoticeButtonEn = 'Add store details';
  static const String storeNoticeButtonAr = 'إضافة بيانات المتجر';

  static const String storeRequiredMessageEn =
      'Please add your store details before continuing with this operation.';
  static const String storeRequiredMessageAr =
      'يُرجى إضافة بيانات متجرك قبل متابعة هذه العملية.';

  static const String storeSuccessMessageEn =
      'Your store details have been added successfully. You can now continue managing your store operations.';
  static const String storeSuccessMessageAr =
      'تمت إضافة بيانات متجرك بنجاح. يمكنك الآن متابعة إدارة المخزون والمبيعات وكافة ميزات التجزئة.';

  // Backward compatibility message aliases
  static const String restaurantNoticeMessageEn =
      'Complete your account setup by adding your restaurant details to enter all your business data and use restaurant-related features.';
  static const String restaurantNoticeMessageAr =
      'أكمل إعداد حسابك بإضافة بيانات مطعمك لإدخال جميع بيانات أعمالك واستخدام الميزات المتعلقة بالمطعم.';

  static const String restaurantNoticeButtonEn = 'Add restaurant details';
  static const String restaurantNoticeButtonAr = 'إضافة بيانات المطعم';

  static const String restaurantRequiredMessageEn =
      'Please add your restaurant details before continuing with this operation.';
  static const String restaurantRequiredMessageAr =
      'يُرجى إضافة بيانات مطعمك قبل متابعة هذه العملية.';

  static const String restaurantSuccessMessageEn =
      'Your restaurant details have been added successfully. You can now continue entering your business data and use restaurant-related features.';
  static const String restaurantSuccessMessageAr =
      'تمت إضافة بيانات مطعمك بنجاح. يمكنك الآن متابعة إدخال بيانات أعمالك واستخدام الميزات المتعلقة بالمطعم.';

  /// Resolves the current [AppUserState] from active BLoC providers in the context.
  static AppUserState getUserState(BuildContext context) {
    AuthCubit? authCubit;
    try {
      authCubit = context.read<AuthCubit>();
    } catch (_) {
      return AppUserState.authenticatedWithRestaurant;
    }

    final authState = authCubit.state;
    final isGuest = authState.isGuest ||
        authState.status != AuthStatus.authenticated;

    if (isGuest) {
      return AppUserState.guest;
    }

    StoreState? storeState;
    try {
      storeState = context.read<StoreCubit>().state;
    } catch (_) {}

    final hasStore = storeState is StoreLoaded && storeState.hasStore;

    if (!hasStore) {
      return AppUserState.authenticatedWithoutRestaurant;
    }

    return AppUserState.authenticatedWithRestaurant;
  }

  /// Verifies if the current user has authenticated credentials.
  static Future<bool> requireAuth({
    required BuildContext context,
    String? returnRoute,
  }) async {
    final state = getUserState(context);
    if (state == AppUserState.guest) {
      await showGuestAuthDialog(context, returnRoute: returnRoute);
      return false;
    }
    return true;
  }

  /// Verifies if the current user has registered a store.
  static Future<bool> requireStore({
    required BuildContext context,
    String? returnRoute,
  }) async {
    final state = getUserState(context);
    if (state == AppUserState.guest) {
      await showGuestAuthDialog(context, returnRoute: returnRoute);
      return false;
    }
    if (state == AppUserState.authenticatedWithoutRestaurant) {
      await showStoreRequiredDialog(context, returnRoute: returnRoute);
      return false;
    }
    return true;
  }

  /// Backward-compatible requireRestaurant
  static Future<bool> requireRestaurant({
    required BuildContext context,
    String? returnRoute,
  }) => requireStore(context: context, returnRoute: returnRoute);

  /// Displays the guest login/register prompt dialog.
  static Future<void> showGuestAuthDialog(
    BuildContext context, {
    String? returnRoute,
  }) async {
    bool isArabic = true;
    try {
      isArabic =
          context.read<SettingsCubit>().state.locale.languageCode == 'ar';
    } catch (_) {}

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BkRadius.lg),
          ),
          title: Row(
            children: [
              Icon(
                Icons.lock_person_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isArabic ? 'تسجيل الدخول مطلوب' : 'Sign In Required',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            isArabic ? guestRestrictionMessageAr : guestRestrictionMessageEn,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              key: const ValueKey('guest_dialog_cancel_button'),
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(isArabic ? 'إلغاء' : 'Cancel'),
            ),
            OutlinedButton(
              key: const ValueKey('guest_dialog_register_button'),
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                try {
                  context.push('/register', extra: returnRoute);
                } catch (_) {
                  context.go('/register');
                }
              },
              child: Text(isArabic ? 'إنشاء حساب' : 'Create Account'),
            ),
            ElevatedButton.icon(
              key: const ValueKey('guest_dialog_login_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                try {
                  context.push('/login', extra: returnRoute);
                } catch (_) {
                  context.go('/login');
                }
              },
              icon: const Icon(Icons.login_rounded, size: 16),
              label: Text(isArabic ? 'تسجيل الدخول' : 'Log In'),
            ),
          ],
        ),
      ),
    );
  }

  /// Displays the store registration requirement dialog.
  static Future<void> showStoreRequiredDialog(
    BuildContext context, {
    String? returnRoute,
  }) async {
    bool isArabic = true;
    try {
      isArabic =
          context.read<SettingsCubit>().state.locale.languageCode == 'ar';
    } catch (_) {}

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BkRadius.lg),
          ),
          title: Row(
            children: [
              Icon(
                Icons.storefront_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isArabic
                      ? 'إضافة بيانات المتجر مطلوبة'
                      : 'Store Details Required',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            isArabic
                ? restaurantRequiredMessageAr
                : restaurantRequiredMessageEn,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              key: const ValueKey('restaurant_required_cancel_button'),
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(isArabic ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton.icon(
              key: const ValueKey('restaurant_required_add_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D64),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                try {
                  context.push('/create-restaurant', extra: returnRoute);
                } catch (_) {
                  context.go('/create-restaurant');
                }
              },
              icon: const Icon(Icons.add_business_outlined, size: 16),
              label: Text(
                isArabic
                    ? restaurantNoticeButtonAr
                    : restaurantNoticeButtonEn,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> showRestaurantRequiredDialog(
    BuildContext context, {
    String? returnRoute,
  }) => showStoreRequiredDialog(context, returnRoute: returnRoute);
}
