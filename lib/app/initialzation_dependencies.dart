import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Auth Feature Dependencies
import 'features/auth/data/datasources/auth_token_storage.dart';
import 'features/auth/data/services/api_auth_service.dart';
import 'features/auth/data/services/auth_service.dart';
import 'features/auth/data/services/mock_auth_service.dart';
import 'features/auth/presentation/cubits/auth_cubit.dart';

// Auto-Update Feature Dependencies
import 'features/autoUpdate/data/datasources/github_release_datasource.dart';
import 'features/autoUpdate/data/datasources/update_preferences_datasource.dart';
import 'features/autoUpdate/data/repositories/app_update_repository_impl.dart';
import 'features/autoUpdate/domain/repositories/app_update_repository.dart';
import 'features/autoUpdate/presentation/cubits/app_update_cubit.dart';

// Users, Roles & Session Dependencies
import 'features/users/data/services/profile_service.dart';
import 'features/users/data/services/roles_service.dart';
import 'features/users/data/services/users_service.dart';
import 'features/users/data/services/working_days_service.dart';
import 'features/users/presentation/cubits/roles_cubit.dart';
import 'features/users/presentation/cubits/session_cubit.dart';

// Store Feature Dependencies
import 'features/store/data/services/store_api_service.dart';
import 'features/store/data/services/store_service.dart';
import 'features/store/presentation/cubits/store_cubit.dart';
import 'features/store/presentation/cubits/store_rbac_cubit.dart';
import 'features/companies/data/services/companies_service.dart';
import 'features/companies/data/repositories/companies_repository_impl.dart';
import 'features/companies/domain/repositories/companies_repository.dart';
import 'features/companies/domain/usecases/company_usecases.dart';
import 'features/companies/presentation/bloc/companies_cubit.dart';
import 'features/items/data/services/items_service.dart';

/// Global service locator instance (GetIt).
///
/// Provides single-point access to registered repositories, data sources,
/// services, and BLoC/Cubit state holders throughout the app.
final singelton = GetIt.instance;

/// Registers and initializes all core dependencies for the application.
///
/// This includes local storage, API/mock services, repositories, and cubits.
/// Called during app startup before launching the widget tree.
Future<void> initializationDependencies() async {
  // Shared Preferences: persistent key-value storage for settings, tokens & cache
  final prefs = await SharedPreferences.getInstance();

  // ---------------------------------------------------------------------------
  // 1. Authentication Layer
  // ---------------------------------------------------------------------------
  if (!singelton.isRegistered<AuthTokenStorage>()) {
    // Token persistence storage backed by SharedPreferences
    final storage = SharedPrefsAuthTokenStorage(prefs: prefs);
    singelton.registerSingleton<AuthTokenStorage>(storage);

    // Switch between mock and real API auth services based on environment flag
    const useMock = bool.fromEnvironment('USE_MOCK_AUTH', defaultValue: true);
    final authService = useMock
        ? MockAuthService(tokenStorage: storage)
        : ApiAuthService(tokenStorage: storage);
    singelton.registerSingleton<AuthService>(authService);
  }

  // ---------------------------------------------------------------------------
  // 2. Application Auto-Update
  // ---------------------------------------------------------------------------
  if (!singelton.isRegistered<AppUpdateRepository>()) {
    // Data source for checking GitHub release tags and download URLs
    final releaseDatasource = HttpGithubReleaseDatasource();

    // Data source for storing update check timestamps and user preferences
    final prefsDatasource = SharedPrefsUpdatePreferencesDatasource(
      prefs: prefs,
    );

    final repository = AppUpdateRepositoryImpl(
      releaseDatasource: releaseDatasource,
      preferencesDatasource: prefsDatasource,
    );
    singelton.registerSingleton<AppUpdateRepository>(repository);

    // Cubit for managing update check, download, and prompt states
    singelton.registerLazySingleton<AppUpdateCubit>(
      () => AppUpdateCubit(repository: repository),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. User & Session Management
  // ---------------------------------------------------------------------------
  if (!singelton.isRegistered<UsersService>()) {
    final usersService = UsersService();
    singelton.registerSingleton<UsersService>(usersService);

    // Cubit to maintain current active user profile and session state
    singelton.registerLazySingleton<SessionCubit>(
      () => SessionCubit(usersService: usersService),
    );
  }

  if (!singelton.isRegistered<ProfileService>()) {
    final storage = singelton<AuthTokenStorage>();
    singelton.registerSingleton<ProfileService>(
      ApiProfileService(tokenStorage: storage),
    );
  }

  if (!singelton.isRegistered<RolesService>()) {
    final storage = singelton<AuthTokenStorage>();
    final rolesService = ApiRolesService(tokenStorage: storage);
    singelton.registerSingleton<RolesService>(rolesService);

    singelton.registerLazySingleton<RolesCubit>(
      () => RolesCubit(rolesService: rolesService)..loadRolesAndPermissions(),
    );
  }

  if (!singelton.isRegistered<WorkingDaysService>()) {
    final storage = singelton<AuthTokenStorage>();
    singelton.registerSingleton<WorkingDaysService>(
      ApiWorkingDaysService(tokenStorage: storage),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Store Feature (Local and Remote Services)
  // ---------------------------------------------------------------------------
  if (!singelton.isRegistered<StoreService>()) {
    final storeService = StoreService();
    singelton.registerSingleton<StoreService>(storeService);
  }

  if (!singelton.isRegistered<StoreApiService>()) {
    const useMock = bool.fromEnvironment('USE_MOCK_AUTH', defaultValue: true);
    final storage = singelton<AuthTokenStorage>();
    final storeService = singelton<StoreService>();

    // Provides store API integration, using mock data or backend service
    final apiService = useMock
        ? MockStoreApiService(
            tokenStorage: storage,
            storeService: storeService,
          )
        : ApiStoreService(
            tokenStorage: storage,
            storeService: storeService,
          );
    singelton.registerSingleton<StoreApiService>(apiService);
  }

  // ---------------------------------------------------------------------------
  // 5. Store State Management
  // ---------------------------------------------------------------------------
  if (!singelton.isRegistered<StoreRbacCubit>()) {
    final api = singelton<StoreApiService>();
    singelton.registerLazySingleton<StoreRbacCubit>(
      () => StoreRbacCubit(apiService: api),
    );
  }

  if (!singelton.isRegistered<StoreCubit>()) {
    final service = singelton<StoreService>();
    final api = singelton.isRegistered<StoreApiService>()
        ? singelton<StoreApiService>()
        : null;
    final rbac = singelton.isRegistered<StoreRbacCubit>()
        ? singelton<StoreRbacCubit>()
        : null;

    singelton.registerLazySingleton<StoreCubit>(
      () => StoreCubit(service: service, apiService: api, rbacCubit: rbac),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Auth Cubit & Startup Auth Verification
  // ---------------------------------------------------------------------------
  if (!singelton.isRegistered<AuthCubit>()) {
    final authCubit = AuthCubit(authService: singelton<AuthService>());
    singelton.registerSingleton<AuthCubit>(authCubit);

    // Eagerly verify if a previously saved session/token is still valid
    await authCubit.checkAuthStatus();
  }

  // ---------------------------------------------------------------------------
  // 7. Companies & Brands
  // ---------------------------------------------------------------------------
  if (!singelton.isRegistered<CompaniesRepository>()) {
    singelton.registerSingleton<CompaniesRepository>(
      CompaniesRepositoryImpl(),
    );
  }

  if (!singelton.isRegistered<CompaniesService>()) {
    singelton.registerSingleton<CompaniesService>(
      CompaniesService(repository: singelton<CompaniesRepository>()),
    );
  }

  if (!singelton.isRegistered<ItemsService>()) {
    singelton.registerSingleton<ItemsService>(ItemsService());
  }

  if (!singelton.isRegistered<CompaniesCubit>()) {
    singelton.registerFactory<CompaniesCubit>(
      () => CompaniesCubit(
        getAllCompanies: GetAllCompaniesUseCase(
          singelton<CompaniesRepository>(),
        ),
        getCompanyById: GetCompanyByIdUseCase(
          singelton<CompaniesRepository>(),
        ),
        saveCompany: SaveCompanyUseCase(singelton<CompaniesRepository>()),
        updateCompany: UpdateCompanyUseCase(singelton<CompaniesRepository>()),
        deleteCompany: DeleteCompanyUseCase(singelton<CompaniesRepository>()),
        itemsService: singelton<ItemsService>(),
      ),
    );
  }
}
