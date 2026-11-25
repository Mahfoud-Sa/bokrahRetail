import 'package:bokrah_design_system/bokrah_design_system.dart';
import 'package:bokrah_retail/app/config/l10n/app_localizations.dart';
import 'package:bokrah_retail/app/config/routes.dart';
import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:bokrah_retail/app/features/auth/presentation/cubits/auth_state.dart';
import 'package:bokrah_retail/app/features/autoUpdate/presentation/cubits/app_update_cubit.dart';
import 'package:bokrah_retail/app/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:bokrah_retail/app/features/settings/presentation/cubits/settings_cubit.dart';
import 'package:bokrah_retail/app/features/settings/presentation/cubits/settings_state.dart';
import 'package:bokrah_retail/app/features/store/presentation/cubits/store_cubit.dart';
import 'package:bokrah_retail/app/features/store/presentation/cubits/store_state.dart';
import 'package:bokrah_retail/app/features/store/presentation/cubits/store_rbac_cubit.dart';
import 'package:bokrah_retail/app/features/sync/presentation/cubits/sync_cubit.dart';
import 'package:bokrah_retail/app/features/users/presentation/cubits/roles_cubit.dart';
import 'package:bokrah_retail/app/features/users/presentation/cubits/session_cubit.dart';
import 'package:bokrah_retail/app/initialzation_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Application entry point.
///
/// Handles framework initialization, dependency registration,
/// and sets up the root [MultiBlocProvider] for global state.
Future<void> main() async {
  // 1. Ensure Flutter widget bindings are initialized before async calls
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize service locator and core app dependencies
  await initializationDependencies();

  // 3. Load device & platform metadata
  final prefs = await SharedPreferences.getInstance();
  final packageInfo = await PackageInfo.fromPlatform();

  // 4. Launch the application with top-level BLoC providers
  runApp(
    MultiBlocProvider(
      providers: [
        // App Settings & Preferences
        BlocProvider(
          create: (context) => SettingsCubit(
            localDataSource: SettingsLocalDataSource(sharedPreferences: prefs),
          ),
        ),

        // Authentication & Session
        BlocProvider(create: (context) => singelton<AuthCubit>()),
        BlocProvider(create: (context) => singelton<SessionCubit>()),
        BlocProvider(create: (context) => singelton<RolesCubit>()),

        // Application Auto-Update
        BlocProvider(create: (context) => singelton<AppUpdateCubit>()),

        // Store RBAC Management
        BlocProvider(create: (context) => singelton<StoreRbacCubit>()),

        // Active Store Context (preloads store data on launch if needed)
        BlocProvider(
          create: (context) {
            final storeCubit = singelton<StoreCubit>();
            if (storeCubit.state is StoreInitial) {
              storeCubit.loadStore();
            }
            return storeCubit;
          },
        ),

        // Store Data Synchronization
        BlocProvider(create: (context) => singelton<SyncCubit>()),
      ],
      child: BokrahRetail(packageInfo: packageInfo),
    ),
  );
}

/// The root application widget.
///
/// Observes [SettingsCubit] to dynamically apply theme modes,
/// high contrast palettes, localization, and routes across the app.
class BokrahRetail extends StatelessWidget {
  final PackageInfo packageInfo;

  const BokrahRetail({super.key, required this.packageInfo});

  void _syncStoreContext(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final storeState = context.read<StoreCubit>().state;
    final storeId = storeState is StoreLoaded ? storeState.activeStoreId : null;
    context.read<SyncCubit>().setStoreContext(
          storeId: storeId,
          isGuest: authState.isGuest || !authState.isAuthenticated,
        );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthCubit, AuthState>(
          listenWhen: (prev, curr) => prev.status != curr.status,
          listener: (context, _) => _syncStoreContext(context),
        ),
        BlocListener<StoreCubit, StoreState>(
          listenWhen: (prev, curr) {
            final prevId = prev is StoreLoaded ? prev.activeStoreId : null;
            final currId = curr is StoreLoaded ? curr.activeStoreId : null;
            return prevId != currId;
          },
          listener: (context, _) => _syncStoreContext(context),
        ),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          final isArabic = state.locale.languageCode == 'ar';

          // Resolve active theme based on contrast settings
          final lightTheme = state.isHighContrast
              ? BkTheme.highContrast(arabic: isArabic)
              : RetailTheme.light(arabic: isArabic);

          final darkTheme = state.isHighContrast
              ? BkTheme.dark(arabic: isArabic)
              : RetailTheme.dark(arabic: isArabic);

          return MaterialApp.router(
            title: packageInfo.appName.isEmpty
                ? 'Bokrah Retail'
                : packageInfo.appName,
            debugShowCheckedModeBanner: false,
            debugShowMaterialGrid: false,

            // Theming configuration
            theme: lightTheme,
            darkTheme: darkTheme,
            highContrastTheme: BkTheme.highContrast(arabic: isArabic),
            highContrastDarkTheme: BkTheme.highContrast(arabic: isArabic),
            themeMode: state.themeMode,

            // Internationalization / Localization
            locale: state.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,

            // Routing configuration via GoRouter
            routerConfig: AppRoutes.routers,
          );
        },
      ),
    );
  }
}
