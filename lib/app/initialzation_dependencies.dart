import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/auth/data/datasources/auth_token_storage.dart';
import 'features/auth/data/services/api_auth_service.dart';
import 'features/auth/data/services/auth_service.dart';
import 'features/auth/data/services/mock_auth_service.dart';
import 'features/autoUpdate/data/datasources/github_release_datasource.dart';
import 'features/autoUpdate/data/datasources/update_preferences_datasource.dart';
import 'features/autoUpdate/data/repositories/app_update_repository_impl.dart';
import 'features/autoUpdate/domain/repositories/app_update_repository.dart';
import 'features/autoUpdate/presentation/cubits/app_update_cubit.dart';
import 'features/users/data/services/users_service.dart';
import 'features/users/presentation/cubits/session_cubit.dart';

import 'features/auth/presentation/cubits/auth_cubit.dart';
import 'features/store/data/services/store_api_service.dart';
import 'features/store/data/services/store_service.dart';
import 'features/store/presentation/cubits/store_cubit.dart';
import 'features/restaurant/data/services/restaurant_api_service.dart';
import 'features/restaurant/data/services/restaurant_service.dart';
import 'features/restaurant/presentation/cubits/restaurant_cubit.dart';

final singelton = GetIt.instance;

Future<void> initializationDependencies() async {
  final prefs = await SharedPreferences.getInstance();

  if (!singelton.isRegistered<AuthTokenStorage>()) {
    final storage = SharedPrefsAuthTokenStorage(prefs: prefs);
    singelton.registerSingleton<AuthTokenStorage>(storage);

    const useMock = bool.fromEnvironment('USE_MOCK_AUTH', defaultValue: true);
    final authService = useMock
        ? MockAuthService(tokenStorage: storage)
        : ApiAuthService(tokenStorage: storage);
    singelton.registerSingleton<AuthService>(authService);
  }

  if (!singelton.isRegistered<AuthCubit>()) {
    final authCubit = AuthCubit(authService: singelton<AuthService>());
    singelton.registerSingleton<AuthCubit>(authCubit);
    authCubit.checkAuthStatus();
  }

  if (!singelton.isRegistered<AppUpdateRepository>()) {
    final releaseDatasource = HttpGithubReleaseDatasource();
    final prefsDatasource = SharedPrefsUpdatePreferencesDatasource(
      prefs: prefs,
    );
    final repository = AppUpdateRepositoryImpl(
      releaseDatasource: releaseDatasource,
      preferencesDatasource: prefsDatasource,
    );
    singelton.registerSingleton<AppUpdateRepository>(repository);
    singelton.registerLazySingleton<AppUpdateCubit>(
      () => AppUpdateCubit(repository: repository),
    );
  }

  if (!singelton.isRegistered<UsersService>()) {
    final usersService = UsersService();
    singelton.registerSingleton<UsersService>(usersService);
    singelton.registerLazySingleton<SessionCubit>(
      () => SessionCubit(usersService: usersService),
    );
  }

  if (!singelton.isRegistered<RestaurantService>()) {
    final restaurantService = RestaurantService();
    singelton.registerSingleton<RestaurantService>(restaurantService);
    if (!singelton.isRegistered<StoreService>()) {
      singelton.registerSingleton<StoreService>(restaurantService);
    }
  } else if (!singelton.isRegistered<StoreService>()) {
    singelton.registerSingleton<StoreService>(singelton<RestaurantService>());
  }

  if (!singelton.isRegistered<StoreApiService>()) {
    const useMock = bool.fromEnvironment('USE_MOCK_AUTH', defaultValue: true);
    final storage = singelton<AuthTokenStorage>();
    final storeService = singelton.isRegistered<StoreService>()
        ? singelton<StoreService>()
        : singelton<RestaurantService>();
    final apiService = useMock
        ? MockRestaurantApiService(
            tokenStorage: storage,
            localRestaurantService: singelton.isRegistered<RestaurantService>()
                ? singelton<RestaurantService>()
                : null,
            storeService: storeService,
          )
        : ApiRestaurantService(
            tokenStorage: storage,
            localRestaurantService: singelton.isRegistered<RestaurantService>()
                ? singelton<RestaurantService>()
                : null,
            storeService: storeService,
          );
    singelton.registerSingleton<StoreApiService>(apiService);
  }

  if (!singelton.isRegistered<StoreCubit>()) {
    final service = singelton.isRegistered<StoreService>()
        ? singelton<StoreService>()
        : singelton<RestaurantService>();
    final api = singelton.isRegistered<StoreApiService>()
        ? singelton<StoreApiService>()
        : null;
    singelton.registerLazySingleton<StoreCubit>(
      () => StoreCubit(
        service: service,
        apiService: api,
      ),
    );
  }
}
