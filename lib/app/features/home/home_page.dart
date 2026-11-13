import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:bokrah_design_system/bokrah_design_system.dart';
import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/config/l10n/app_localizations.dart';
import 'package:bokrah_retail/app/features/autoUpdate/presentation/app_update_screen.dart';
import 'package:bokrah_retail/app/features/autoUpdate/presentation/cubits/app_update_cubit.dart';
import 'package:bokrah_retail/app/features/autoUpdate/presentation/cubits/app_update_state.dart';
import 'package:bokrah_retail/app/features/autoUpdate/presentation/dialogs/update_prompt_dialog.dart';
import 'package:bokrah_retail/app/features/settings/presentation/cubits/settings_cubit.dart';
import 'package:bokrah_retail/app/features/settings/presentation/cubits/settings_state.dart';
import 'package:bokrah_retail/app/features/accounting_playground/accounting.dart';
import 'package:bokrah_retail/app/features/users/presentation/pages/users_page.dart';
import 'package:bokrah_retail/app/features/users/presentation/pages/profile_page.dart';
import 'package:bokrah_retail/app/features/store/presentation/pages/store_info_page.dart';
import 'package:bokrah_retail/app/features/store/presentation/widgets/store_context_switcher.dart';
import 'package:bokrah_retail/app/features/store/presentation/cubits/store_cubit.dart';
import 'package:bokrah_retail/app/features/restaurant/presentation/pages/restaurant_info_page.dart';
import 'package:bokrah_retail/app/features/home/notification_page.dart';
import 'package:bokrah_retail/app/features/home/side_bar_item.dart';
import 'package:bokrah_retail/app/features/common/presentation/pages/coming_soon_page.dart';
import 'package:bokrah_retail/app/features/users/data/entities/user_entity.dart';
import 'package:bokrah_retail/app/features/users/presentation/cubits/session_cubit.dart';
import 'package:bokrah_retail/app/features/users/presentation/cubits/session_state.dart';
import 'package:bokrah_retail/app/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:bokrah_retail/app/features/auth/presentation/cubits/auth_state.dart';
import 'package:bokrah_retail/app/features/auth/presentation/widgets/guest_restricted_view.dart';
import 'package:bokrah_retail/app/features/restaurant/presentation/cubits/restaurant_cubit.dart';
import 'package:bokrah_retail/app/core/auth/app_access_guard.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;
  PackageInfo? _packageInfo;
  bool isItemsExpanded = true;
  bool isSettingsExpanded = false;
  bool _hasPromptedUpdateThisSession = false;
  final PlaygroundController _accountingController = PlaygroundController();

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppUpdateCubit>().checkForUpdates(isManual: false);
    });
  }

  @override
  void dispose() {
    _accountingController.dispose();
    super.dispose();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _packageInfo = info;
      });
    }
  }

  void _showVersionInfo() {
    if (_packageInfo == null) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          scrollable: true,
          title: const Text('معلومات التطبيق'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('اسم التطبيق:', _packageInfo!.appName),
              const SizedBox(height: 8),
              _buildInfoRow('الإصدار:', _packageInfo!.version),
              const SizedBox(height: 8),
              _buildInfoRow('رقم البناء:', _packageInfo!.buildNumber),
              const SizedBox(height: 8),
              _buildInfoRow('اسم الحزمة:', _packageInfo!.packageName),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AppUpdateScreen(),
                  ),
                );
              },
              child: const Text('التحقق من التحديثات'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('موافق'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  Future<void> _showLogoutDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final isArabic =
            dialogContext.read<SettingsCubit>().state.locale.languageCode ==
                'ar';
        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            scrollable: true,
            title: Text(isArabic ? 'بكرة للمحاسبة' : 'Bokrah Accounting'),
            content: Text(
              isArabic
                  ? 'هل أنت متأكد من رغبتك في تسجيل الخروج؟'
                  : 'Are you sure you want to log out?',
            ),
            actions: <Widget>[
              TextButton(
                child: Text(isArabic ? 'إلغاء' : 'Cancel'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(isArabic ? 'تسجيل الخروج' : 'Log Out'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  try {
                    context.read<AuthCubit>().logout();
                  } catch (_) {}
                  context.go('/login');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showGuestPromptDialog({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    final isArabic =
        context.read<SettingsCubit>().state.locale.languageCode == 'ar';
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
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
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 14, height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(isArabic ? 'إلغاء' : 'Cancel'),
            ),
            OutlinedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/register');
              },
              child: Text(isArabic ? 'إنشاء حساب' : 'Create Account'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/login');
              },
              icon: const Icon(Icons.login_rounded, size: 16),
              label: Text(isArabic ? 'تسجيل الدخول' : 'Sign In'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserMenu({bool isMobile = false}) {
    final isArabic =
        context.watch<SettingsCubit>().state.locale.languageCode == 'ar';
    AuthState? authState;
    try {
      authState = context.watch<AuthCubit>().state;
    } catch (_) {}
    final isGuest = authState?.isGuest ?? false;

    try {
      context.watch<RestaurantCubit>();
    } catch (_) {}

    if (isGuest) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isMobile) ...[
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  isArabic ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Text(
                  isArabic ? 'حساب زائر' : 'Guest User',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                BkBadge(
                  label: isArabic ? 'ضيف' : 'Guest',
                  tone: BkTone.neutral,
                ),
              ],
            ),
            const SizedBox(width: BkSpace.sm),
          ],
          FilledButton.tonalIcon(
            key: const ValueKey('header_login_button'),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.login_rounded, size: 16),
            label: Text(
              isArabic ? 'تسجيل الدخول' : 'Sign In',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: BkSpace.xs),
            OutlinedButton.icon(
              key: const ValueKey('header_register_button'),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              onPressed: () => context.go('/register'),
              icon: const Icon(Icons.person_add_outlined, size: 16),
              label: Text(
                isArabic ? 'إنشاء حساب' : 'Create Account',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
          const SizedBox(width: BkSpace.xs),
          PopupMenuButton<String>(
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            icon: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: CircleAvatar(
                radius: isMobile ? 14 : 16,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                child: Icon(
                  Icons.person_outline,
                  size: isMobile ? 18 : 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            onSelected: (value) {
              if (value == 'login') {
                context.go('/login');
              } else if (value == 'register') {
                context.go('/register');
              } else if (value == 'app_info') {
                _showVersionInfo();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'login',
                child: ListTile(
                  leading: const Icon(Icons.login_rounded),
                  title: Text(isArabic ? 'تسجيل الدخول' : 'Sign In'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              PopupMenuItem<String>(
                value: 'register',
                child: ListTile(
                  leading: const Icon(Icons.person_add_outlined),
                  title: Text(isArabic ? 'إنشاء حساب' : 'Create Account'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'app_info',
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(isArabic ? 'معلومات التطبيق' : 'App Information'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      );
    }

    SessionState? sessionState;
    try {
      sessionState = context.watch<SessionCubit>().state;
    } catch (_) {}
    final operator = sessionState?.currentOperator;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (operator != null && !isMobile) ...[
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                isArabic ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              Text(
                operator.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              BkBadge(
                label: operator.role.displayName,
                tone: operator.role == OperatorRole.admin
                    ? BkTone.warning
                    : operator.role == OperatorRole.accountant
                        ? BkTone.info
                        : BkTone.success,
              ),
            ],
          ),
          const SizedBox(width: BkSpace.sm),
        ],
        PopupMenuButton<String>(
          offset: const Offset(0, 50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          icon: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: CircleAvatar(
              radius: isMobile ? 14 : 16,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(
                Icons.person,
                size: isMobile ? 18 : 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          onSelected: (value) {
            if (value == 'profile') {
              setState(() => selectedIndex = 12);
            } else if (value == 'restaurant') {
              setState(() => selectedIndex = 13);
            } else if (value == 'add_restaurant') {
              try {
                context.push('/create-restaurant', extra: '/home');
              } catch (_) {
                context.go('/create-restaurant');
              }
            } else if (value == 'logout') {
              _showLogoutDialog();
            }
          },
          itemBuilder: (BuildContext context) {
            final userState = AppAccessGuard.getUserState(context);
            return <PopupMenuEntry<String>>[
              if (userState == AppUserState.authenticatedWithoutRestaurant) ...[
                PopupMenuItem<String>(
                  value: 'add_restaurant',
                  child: ListTile(
                    leading: Icon(
                      Icons.add_business_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      isArabic
                          ? AppAccessGuard.restaurantNoticeButtonAr
                          : AppAccessGuard.restaurantNoticeButtonEn,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                const PopupMenuDivider(),
              ],
              if (operator?.role == OperatorRole.admin ||
                  userState == AppUserState.authenticatedWithRestaurant) ...[
                PopupMenuItem<String>(
                  value: 'restaurant',
                  child: ListTile(
                    leading: const Icon(Icons.storefront_outlined),
                    title: Text(isArabic ? 'بيانات المتجر' : 'Store Profile'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                const PopupMenuDivider(),
              ],
            PopupMenuItem<String>(
              value: 'profile',
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(isArabic ? 'الملف الشخصي' : 'My Profile'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'logout',
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: Text(
                  isArabic ? 'تسجيل الخروج' : 'Log Out',
                  style: const TextStyle(color: Colors.red),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ];
        },
      ),
      ],
    );
  }

  String _pageTitle(int index, bool isArabic) {
    if (isArabic) {
      return switch (index) {
        0 => 'لوحة التحكم المحاسبية',
        1 => 'المبيعات والمعاملات',
        2 => 'القيود اليومية',
        3 => 'إدارة الفواتير',
        4 => 'شجرة الحسابات',
        5 => 'التقارير المالية',
        6 => 'قائمة العناصر',
        7 => 'فئات المنتجات',
        8 => 'إدارة المستودعات',
        9 => 'وحدات القياس',
        10 => 'إدارة الباركودات',
        11 => 'إدارة المستخدمين',
        12 => 'الملف الشخصي',
        13 => 'بيانات المطعم',
        _ => AppLocalizations.of(context)?.appName ?? 'بكرة للمحاسبة',
      };
    }
    return switch (index) {
      0 => 'Accounting Dashboard',
      1 => 'Sales & Transactions',
      2 => 'Journal Entries',
      3 => 'Invoice Management',
      4 => 'Chart of Accounts',
      5 => 'Financial Reports',
      6 => 'Items Catalogue',
      7 => 'Product Categories',
      8 => 'Warehouse Management',
      9 => 'Units of Measure',
      10 => 'Barcode Management',
      11 => 'User Management',
      12 => 'My Profile',
      13 => 'Store Profile',
      _ => AppLocalizations.of(context)?.appName ?? 'Bokrah Accounting',
    };
  }

  IconData _pageIcon(int index) {
    return switch (index) {
      0 => Icons.dashboard_outlined,
      1 => Icons.receipt_long_outlined,
      2 => Icons.edit_note_outlined,
      3 => Icons.description_outlined,
      4 => Icons.account_tree_outlined,
      5 => Icons.analytics_outlined,
      6 => Icons.inventory_2_outlined,
      7 => Icons.category_outlined,
      8 => Icons.warehouse_outlined,
      9 => Icons.straighten_outlined,
      10 => Icons.qr_code_outlined,
      11 => Icons.manage_accounts_outlined,
      12 => Icons.person_outline,
      13 => Icons.storefront_outlined,
      _ => Icons.circle_outlined,
    };
  }

  IconData _themeIcon(BkThemeMode mode) {
    return switch (mode) {
      BkThemeMode.light => Icons.light_mode_outlined,
      BkThemeMode.dark => Icons.dark_mode_outlined,
      BkThemeMode.highContrast => Icons.contrast,
    };
  }

  String _themeTooltip(BkThemeMode mode, bool isArabic) {
    if (isArabic) {
      return switch (mode) {
        BkThemeMode.light => 'المظهر: فاتح',
        BkThemeMode.dark => 'المظهر: داكن',
        BkThemeMode.highContrast => 'المظهر: عالي التباين',
      };
    }
    return switch (mode) {
      BkThemeMode.light => 'Theme: Light',
      BkThemeMode.dark => 'Theme: Dark',
      BkThemeMode.highContrast => 'Theme: High Contrast',
    };
  }

  Widget _buildUpdateActionButton({
    required BuildContext context,
    required bool isMobile,
    required bool isArabic,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    if (isMobile) {
      return Tooltip(
        message: isArabic ? 'تحديث متاح للتطبيق' : 'App update available',
        child: Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.system_update_alt_rounded),
              color: colorScheme.primary,
              tooltip: isArabic ? 'تحديث متاح للتطبيق' : 'App update available',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AppUpdateScreen(),
                  ),
                );
              },
            ),
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Tooltip(
        message: isArabic ? 'يوجد إصدار جديد للتطبيق' : 'New version available',
        child: FilledButton.tonalIcon(
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            backgroundColor:
                colorScheme.primaryContainer.withValues(alpha: 0.7),
            foregroundColor: colorScheme.onPrimaryContainer,
          ),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AppUpdateScreen(),
              ),
            );
          },
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.system_update_alt_rounded, size: 18),
              Positioned(
                right: -3,
                top: -3,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          label: Text(
            isArabic ? 'تحديث جديد' : 'Update Available',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final isArabic =
        context.watch<SettingsCubit>().state.locale.languageCode == 'ar';
    AuthState? authState;
    try {
      authState = context.watch<AuthCubit>().state;
    } catch (_) {}
    final isGuest = authState?.isGuest ?? false;

    try {
      context.watch<RestaurantCubit>();
    } catch (_) {}

    AppUserState userState = AppUserState.guest;
    try {
      userState = AppAccessGuard.getUserState(context);
    } catch (_) {}

    _accountingController.canPerformAccounting =
        (userState == AppUserState.authenticatedWithRestaurant);
    _accountingController.restrictionMessage = (userState == AppUserState.guest)
        ? (isArabic
            ? AppAccessGuard.guestRestrictionMessageAr
            : AppAccessGuard.guestRestrictionMessageEn)
        : (isArabic
            ? AppAccessGuard.restaurantRequiredMessageAr
            : AppAccessGuard.restaurantRequiredMessageEn);

    final pages = [
      // 0: Accounting Dashboard
      ComingSoonView.dashboard(
        onBack: () => setState(() => selectedIndex = 0),
      ),
      // 1: Transactions & Sales
      ComingSoonView.transactions(
        onBack: () => setState(() => selectedIndex = 0),
      ),
      // 2: Journal Entries
      ComingSoonView.journalEntries(
        onBack: () => setState(() => selectedIndex = 0),
      ),
      // 3: Invoices
      ComingSoonView.invoices(
        onBack: () => setState(() => selectedIndex = 0),
      ),
      // 4: Chart of Accounts
      ComingSoonView.chartOfAccounts(
        onBack: () => setState(() => selectedIndex = 0),
      ),
      // 5: Financial Reports
      ComingSoonView.financialReports(
        onBack: () => setState(() => selectedIndex = 0),
      ),
      // 6: Items
      ComingSoonView.items(
        onBack: () => setState(() => selectedIndex = 0),
      ),
      // 7: Categories
      ComingSoonView.categories(
        onBack: () => setState(() => selectedIndex = 0),
      ),
      // 8: Warehouses
      ComingSoonView.warehouses(
        onBack: () => setState(() => selectedIndex = 0),
      ),
      // 9: Units
      ComingSoonView.units(
        onBack: () => setState(() => selectedIndex = 0),
      ),
      // 10: Barcodes
      ComingSoonView.barcodes(
        onBack: () => setState(() => selectedIndex = 0),
      ),
      // 11: Users
      isGuest
          ? GuestRestrictedView(
              title: isArabic ? 'إدارة المستخدمين' : 'User Management',
              description: isArabic
                  ? 'إدارة فريق العمل والأدوار والصلاحيات تتطلب تسجيل الدخول بحساب مسؤول معتمد.'
                  : 'Managing team members, roles, and permissions requires signing in with an authorized administrator account.',
              onBackToDashboard: () => setState(() => selectedIndex = 0),
            )
          : const UsersPage(),
      // 12: Profile
      isGuest
          ? GuestRestrictedView(
              title: isArabic ? 'الملف الشخصي' : 'User Profile',
              description: isArabic
                  ? 'الملف الشخصي متاح للمستخدمين المسجلين فقط. سجل الدخول للوصول إلى بياناتك الشخصية.'
                  : 'User profiles are only available for authenticated accounts. Sign in to view and edit your profile.',
              onBackToDashboard: () => setState(() => selectedIndex = 0),
            )
          : const ProfilePage(),
      // 13: Store Info
      isGuest
          ? GuestRestrictedView(
              title: isArabic ? 'بيانات المتجر' : 'Store Profile',
              description: isArabic
                  ? 'تعديل السجل التجاري والبيانات الضريبية للمنشأة يتطلب تسجيل الدخول بحساب مسؤول معتمد.'
                  : 'Modifying commercial registration and enterprise settings requires signing in with an authorized account.',
              onBackToDashboard: () => setState(() => selectedIndex = 0),
            )
          : const StoreInfoPage(),
    ];

    SessionState? sessionState;
    try {
      sessionState = context.watch<SessionCubit>().state;
    } catch (_) {}
    final canAccessAccounting = sessionState?.canAccessAccounting ?? true;
    final canAccessUsers = sessionState?.canAccessUsers ?? true;

    Widget sidebarContent = Container(
      width: 260,
      decoration: BoxDecoration(
        color: AppTheme.sidebarBackground,
        border: Border(
          right: isArabic
              ? BorderSide.none
              : const BorderSide(
                  color: AppTheme.sidebarBorder,
                ),
          left: isArabic
              ? const BorderSide(
                  color: AppTheme.sidebarBorder,
                )
              : BorderSide.none,
        ),
      ),
      child: Column(
        children: [
          // Brand Logo Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.actionBlue,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? "بكرة للتجزئة" : "Bokra Retail",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 2,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.paleOrange,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isArabic ? "المؤسسات" : "Enterprise",
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.deepCobalt,
                              ),
                            ),
                          ),
                          Text(
                            _packageInfo != null
                                ? 'v${_packageInfo!.version}'
                                : 'v3.5.1',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.sidebarBorder),

          // Scrollable navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // 1. Accounting & Finance
                if (canAccessAccounting) ...[
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      isArabic ? "المحاسبة والمالية" : "Accounting & Finance",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                        color: AppTheme.darkPrimaryAction,
                      ),
                    ),
                  ),
                  SidebarItem(
                    icon: Icons.dashboard_outlined,
                    label: isArabic ? "لوحة التحكم" : "Dashboard",
                    isSelected: selectedIndex == 0,
                    onTap: () {
                      setState(() => selectedIndex = 0);
                      if (isMobile) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  SidebarItem(
                    icon: Icons.receipt_long_outlined,
                    label: isArabic ? "المبيعات والمعاملات" : "Transactions",
                    isSelected: selectedIndex == 1,
                    onTap: () {
                      setState(() => selectedIndex = 1);
                      if (isMobile) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  SidebarItem(
                    icon: Icons.edit_note_outlined,
                    label: isArabic ? "القيود اليومية" : "Journal Entries",
                    isSelected: selectedIndex == 2,
                    onTap: () {
                      setState(() => selectedIndex = 2);
                      if (isMobile) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
                SidebarItem(
                  icon: Icons.description_outlined,
                  label: isArabic ? "إدارة الفواتير" : "Invoices",
                  isSelected: selectedIndex == 3,
                  onTap: () {
                    setState(() => selectedIndex = 3);
                    if (isMobile) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
                if (canAccessAccounting) ...[
                  SidebarItem(
                    icon: Icons.account_tree_outlined,
                    label: isArabic ? "شجرة الحسابات" : "Chart of Accounts",
                    isSelected: selectedIndex == 4,
                    onTap: () {
                      setState(() => selectedIndex = 4);
                      if (isMobile) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  SidebarItem(
                    icon: Icons.analytics_outlined,
                    label: isArabic ? "التقارير المالية" : "Financial Reports",
                    isSelected: selectedIndex == 5,
                    onTap: () {
                      setState(() => selectedIndex = 5);
                      if (isMobile) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Divider(height: 1),
                ),

                // 2. Inventory & Operations
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    isArabic ? "المخزون والعمليات" : "Inventory & Operations",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                      color: AppTheme.darkPrimaryAction,
                    ),
                  ),
                ),
                SidebarItem(
                  icon: Icons.inventory_2_outlined,
                  label: isArabic ? "العناصر والمخزون" : "Items & Stock",
                  isSelected: selectedIndex >= 6 && selectedIndex <= 10,
                  hasArrow: true,
                  isExpanded: isItemsExpanded,
                  onTap: () =>
                      setState(() => isItemsExpanded = !isItemsExpanded),
                ),
                if (isItemsExpanded) ...[
                  SidebarItem(
                    icon: Icons.list_alt,
                    label: isArabic ? "قائمة العناصر" : "Items List",
                    isSelected: selectedIndex == 6,
                    onTap: () {
                      setState(() => selectedIndex = 6);
                      if (isMobile) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  SidebarItem(
                    icon: Icons.category_outlined,
                    label: isArabic ? "فئات المنتجات" : "Categories",
                    isSelected: selectedIndex == 7,
                    onTap: () {
                      setState(() => selectedIndex = 7);
                      if (isMobile) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  SidebarItem(
                    icon: Icons.warehouse_outlined,
                    label: isArabic ? "إدارة المستودعات" : "Warehouses",
                    isSelected: selectedIndex == 8,
                    onTap: () {
                      setState(() => selectedIndex = 8);
                      if (isMobile) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  SidebarItem(
                    icon: Icons.straighten,
                    label: isArabic ? "وحدات القياس" : "Units",
                    isSelected: selectedIndex == 9,
                    onTap: () {
                      setState(() => selectedIndex = 9);
                      if (isMobile) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  SidebarItem(
                    icon: Icons.qr_code,
                    label: isArabic ? "الباركودات" : "Barcodes",
                    isSelected: selectedIndex == 10,
                    onTap: () {
                      setState(() => selectedIndex = 10);
                      if (isMobile) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Divider(height: 1),
                ),

                // 3. System & Administration
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    isArabic ? "النظام والإدارة" : "System & Settings",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                      color: AppTheme.darkPrimaryAction,
                    ),
                  ),
                ),
                SidebarItem(
                  icon: Icons.settings_outlined,
                  label: isArabic ? "الإعدادات والمستخدمين" : "Settings",
                  isSelected: selectedIndex >= 11 && selectedIndex <= 13,
                  hasArrow: true,
                  isExpanded: isSettingsExpanded,
                  onTap: () => setState(
                      () => isSettingsExpanded = !isSettingsExpanded),
                ),
                if (isSettingsExpanded) ...[
                  SidebarItem(
                    icon: Icons.storefront_outlined,
                    label: isArabic ? "بيانات المتجر" : "Store Profile",
                    isSelected: selectedIndex == 13,
                    trailing: isGuest
                        ? const Icon(
                            Icons.lock_outline,
                            size: 15,
                            color: Colors.white70,
                          )
                        : null,
                    onTap: () {
                      if (isGuest) {
                        _showGuestPromptDialog(
                          context: context,
                          title:
                              isArabic ? "بيانات المتجر" : "Store Profile",
                          message: isArabic
                              ? "تعديل بيانات المتجر يتطلب تسجيل الدخول بحساب مسؤول معتمد."
                              : "Managing store profile requires signing in with an administrator account.",
                        );
                      }
                      setState(() => selectedIndex = 13);
                      if (isMobile) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  if (canAccessUsers || isGuest)
                    SidebarItem(
                      icon: Icons.manage_accounts_outlined,
                      label: isArabic ? "إدارة المستخدمين" : "Users Management",
                      isSelected: selectedIndex == 11,
                      trailing: isGuest
                          ? const Icon(
                              Icons.lock_outline,
                              size: 15,
                              color: Colors.white70,
                            )
                          : null,
                      onTap: () {
                        if (isGuest) {
                          _showGuestPromptDialog(
                            context: context,
                            title: isArabic
                                ? "إدارة المستخدمين"
                                : "Users Management",
                            message: isArabic
                                ? "إدارة المستخدمين والصلاحيات تتطلب تسجيل الدخول بحساب مسؤول."
                                : "Managing users requires signing in with an administrator account.",
                          );
                        }
                        setState(() => selectedIndex = 11);
                        if (isMobile) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  SidebarItem(
                    icon: Icons.person_outline,
                    label: isArabic ? "ملفي الشخصي" : "Profile",
                    isSelected: selectedIndex == 12,
                    trailing: isGuest
                        ? const Icon(
                            Icons.lock_outline,
                            size: 15,
                            color: Colors.white70,
                          )
                        : null,
                    onTap: () {
                      if (isGuest) {
                        _showGuestPromptDialog(
                          context: context,
                          title: isArabic ? "الملف الشخصي" : "Profile",
                          message: isArabic
                              ? "الملف الشخصي متاح للمستخدمين المسجلين فقط."
                              : "User profile is only available for authenticated accounts.",
                        );
                      }
                      setState(() => selectedIndex = 12);
                      if (isMobile) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              ],
            ),
          ),

          // Version footer
          const Divider(height: 1, color: AppTheme.sidebarBorder),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    if (_packageInfo != null) {
                      _showVersionInfo();
                    }
                  },
                  child: Text(
                    _packageInfo != null
                        ? 'v${_packageInfo!.version}'
                        : 'v3.5.1',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white70,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    isArabic ? 'بكرة © 2026' : 'Bokra Retail © 2026',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    Widget topBar = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Breadcrumb & Page title
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _pageIcon(selectedIndex),
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  isArabic ? "بكرة / " : "Bokrah / ",
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.45),
                  ),
                ),
                Flexible(
                  child: Text(
                    _pageTitle(selectedIndex, isArabic),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Actions
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                // Multi-Store Switcher
                const StoreContextSwitcher(isMobile: false),
                const SizedBox(width: 8),

                // Language & Theme Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () =>
                          context.read<SettingsCubit>().toggleLanguage(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: Text(
                          isArabic ? 'EN' : 'العربية',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 16,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.15),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      tooltip: _themeTooltip(
                        context.watch<SettingsCubit>().state.bkThemeMode,
                        isArabic,
                      ),
                      icon: Icon(
                        _themeIcon(
                          context.watch<SettingsCubit>().state.bkThemeMode,
                        ),
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () {
                        context.read<SettingsCubit>().cycleThemeMode();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              _buildUserMenu(),
              const SizedBox(width: 4),

              // Special update button on top bar (shown only if a new update is available)
              BlocBuilder<AppUpdateCubit, AppUpdateState>(
                builder: (context, updateState) {
                  if (!updateState.hasUnskippedUpdate) {
                    return const SizedBox.shrink();
                  }
                  return _buildUpdateActionButton(
                    context: context,
                    isMobile: false,
                    isArabic: isArabic,
                  );
                },
              ),

              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 24),
                tooltip: isArabic ? 'الإشعارات' : 'Notifications',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NotificationsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      ],
    ),
  );

    return BlocListener<AppUpdateCubit, AppUpdateState>(
      listener: (context, state) {
        if (state is AppUpdateAvailable &&
            state.hasUnskippedUpdate &&
            !_hasPromptedUpdateThisSession) {
          _hasPromptedUpdateThisSession = true;
          UpdatePromptDialog.show(
            context,
            release: state.release,
            installedVersion: state.installedVersion,
          );
        }
      },
      child: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          appBar: isMobile
              ? AppBar(
                  title: Text(
                    _pageTitle(selectedIndex, isArabic),
                    overflow: TextOverflow.ellipsis,
                  ),
                  actions: [
                    IconButton(
                      tooltip: _themeTooltip(
                        context.watch<SettingsCubit>().state.bkThemeMode,
                        isArabic,
                      ),
                      icon: Icon(
                        _themeIcon(
                          context.watch<SettingsCubit>().state.bkThemeMode,
                        ),
                      ),
                      onPressed: () {
                        context.read<SettingsCubit>().cycleThemeMode();
                      },
                    ),
                    _buildUserMenu(isMobile: true),
                    // Special update button on mobile app bar (shown only if a new update is available)
                    BlocBuilder<AppUpdateCubit, AppUpdateState>(
                      builder: (context, updateState) {
                        if (!updateState.hasUnskippedUpdate) {
                          return const SizedBox.shrink();
                        }
                        return _buildUpdateActionButton(
                          context: context,
                          isMobile: true,
                          isArabic: isArabic,
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, size: 22),
                      tooltip: isArabic ? 'الإشعارات' : 'Notifications',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const NotificationsPage(),
                          ),
                        );
                      },
                    ),
                  ],
                )
              : null,
          drawer: isMobile
              ? Drawer(
                  child: SafeArea(
                    child: sidebarContent,
                  ),
                )
              : null,
          body: isMobile
              ? Column(
                  children: [
                    _buildVerificationBanner(context, isArabic),
                    _buildRestaurantSetupBanner(context, isArabic),
                    Expanded(child: pages[selectedIndex]),
                  ],
                )
              : Row(
                  children: [
                    sidebarContent,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          topBar,
                          _buildVerificationBanner(context, isArabic),
                          _buildRestaurantSetupBanner(context, isArabic),
                          Expanded(child: pages[selectedIndex]),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildVerificationBanner(BuildContext context, bool isArabic) {
    bool isEmailVerified = true;
    bool isAccountVerified = true;
    try {
      final authState = context.watch<AuthCubit>().state;
      if (authState.status == AuthStatus.authenticated) {
        isEmailVerified = authState.isEmailVerified;
        isAccountVerified = authState.isAccountVerified;
      }
    } catch (_) {}

    try {
      final currentOperator =
          context.watch<SessionCubit>().state.currentOperator;
      if (currentOperator != null) {
        if (!currentOperator.isEmailVerified) isEmailVerified = false;
        if (!currentOperator.isAccountVerified) isAccountVerified = false;
      }
    } catch (_) {}

    if (isEmailVerified && isAccountVerified) {
      return const SizedBox.shrink();
    }

    return Container(
      key: const ValueKey('verification_notice_banner'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.warningSurface,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.warning.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 20, color: AppTheme.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              !isEmailVerified && !isAccountVerified
                  ? (isArabic
                      ? 'تنبيه: يُرجى تأكيد البريد الإلكتروني وتوثيق الحساب للاستفادة من كافة الصلاحيات.'
                      : 'Notice: Please verify your email and complete account verification to access full features.')
                  : (!isEmailVerified
                      ? (isArabic
                          ? 'تنبيه: يُرجى تأكيد بريدك الإلكتروني لتأمين حسابك.'
                          : 'Notice: Please verify your email address to secure your account.')
                      : (isArabic
                          ? 'تنبيه: حسابك قيد المراجعة والتوثيق.'
                          : 'Notice: Please complete your account verification.')),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantSetupBanner(BuildContext context, bool isArabic) {
    AppUserState userState = AppUserState.guest;
    try {
      userState = AppAccessGuard.getUserState(context);
    } catch (_) {}

    if (userState != AppUserState.authenticatedWithoutRestaurant) {
      return const SizedBox.shrink();
    }

    return Container(
      key: const ValueKey('restaurant_setup_notice_banner'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.subtleSurface,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.border,
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppTheme.actionBlue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront_outlined,
              size: 20,
              color: AppTheme.actionBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isArabic
                  ? AppAccessGuard.restaurantNoticeMessageAr
                  : AppAccessGuard.restaurantNoticeMessageEn,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            key: const ValueKey('add_restaurant_details_banner_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.actionBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(BkRadius.md),
              ),
            ),
            onPressed: () {
              try {
                context.push('/create-restaurant', extra: '/home');
              } catch (_) {
                context.go('/create-restaurant');
              }
            },
            icon: const Icon(Icons.add_business_outlined, size: 16),
            label: Text(
              isArabic
                  ? AppAccessGuard.restaurantNoticeButtonAr
                  : AppAccessGuard.restaurantNoticeButtonEn,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
