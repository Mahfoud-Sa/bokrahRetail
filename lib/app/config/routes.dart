import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:bokrah_retail/app/features/auth/login_page.dart';
import 'package:bokrah_retail/app/features/auth/register_page.dart';
import 'package:bokrah_retail/app/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:bokrah_retail/app/features/auth/presentation/cubits/auth_state.dart';
import 'package:bokrah_retail/app/features/auth/data/models/country_code_model.dart';
import 'package:bokrah_retail/app/features/store/presentation/cubits/store_cubit.dart';
import 'package:bokrah_retail/app/features/store/presentation/cubits/store_state.dart';
import 'package:bokrah_retail/app/features/home/home_page.dart';
import 'package:bokrah_retail/app/features/items/presentation/pages/add_item_page.dart';
import 'package:bokrah_retail/app/features/items/data/entities/item_entity.dart';
import 'package:bokrah_retail/app/features/users/presentation/pages/users_page.dart';
import 'package:bokrah_retail/app/features/users/presentation/pages/profile_page.dart';
import 'package:bokrah_retail/app/features/store/presentation/pages/store_info_page.dart';
import 'package:bokrah_retail/app/features/store/presentation/pages/create_store_page.dart';
import 'package:bokrah_retail/app/features/common/presentation/pages/coming_soon_page.dart';
import 'package:bokrah_retail/app/features/autoUpdate/presentation/app_update_screen.dart';
import 'package:bokrah_retail/app/initialzation_dependencies.dart';

/// Reactive Listenable that merges multiple streams to notify GoRouter of state updates.
class GoRouterRefreshStream extends ChangeNotifier {
  late final List<StreamSubscription<dynamic>> _subscriptions;

  GoRouterRefreshStream(List<Stream<dynamic>> streams) {
    _subscriptions = streams
        .map((stream) => stream.asBroadcastStream().listen((_) => notifyListeners()))
        .toList();
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}

class AppRoutes {
  /// Classified route categories
  static const Set<String> publicAuthRoutes = {'/login', '/register'};
  static const Set<String> storeOnboardingRoutes = {
    '/store-info',
    '/create-store',
    '/store/create',
  };
  static const Set<String> hardGuardedRoutes = {'/profile', '/users'};

  /// Resolves the default destination after sign-in based on role hierarchy or an existing returnRoute.
  static String resolveRoleDestination(
    List<String> rawRoles, {
    String? returnRoute,
  }) {
    if (returnRoute != null &&
        returnRoute.isNotEmpty &&
        returnRoute != '/login' &&
        returnRoute != '/register') {
      return returnRoute;
    }
    final roles = rawRoles.map((r) => r.toLowerCase().trim()).toList();
    if (roles.contains('admin')) {
      return '/admin/dashboard';
    } else if (roles.contains('store') || roles.contains('retail')) {
      return '/store/dashboard';
    } else if (roles.contains('delivery')) {
      return '/delivery/orders';
    }
    return '/home';
  }

  /// Pure redirection evaluator for testability and declarative route checking.
  static String? evaluateRedirect({
    required String path,
    String? returnRoute,
    required AuthState authState,
    required StoreState storeState,
  }) {
    final isGuest = authState.status == AuthStatus.guest;
    final isAuthenticated = authState.status == AuthStatus.authenticated;
    final hasStore = storeState is StoreLoaded && storeState.hasStore;

    // Root location
    if (path == '/') {
      if (!isAuthenticated) return '/login';
      if (!hasStore) return '/store-info';
      return resolveRoleDestination(authState.roles, returnRoute: returnRoute);
    }

    // Public Auth Routes (/login, /register)
    if (publicAuthRoutes.contains(path)) {
      if (!isAuthenticated) {
        return null; // Visitors and guests can freely view login and register
      }
      if (!hasStore) {
        return (returnRoute != null &&
                returnRoute.isNotEmpty &&
                !publicAuthRoutes.contains(returnRoute))
            ? returnRoute
            : '/store-info';
      }
      return resolveRoleDestination(authState.roles, returnRoute: returnRoute);
    }

    // Store Onboarding Routes (/store-info, /create-store, /store/create)
    if (storeOnboardingRoutes.contains(path)) {
      if (!isAuthenticated) {
        final encoded = Uri.encodeComponent(path);
        return '/login?returnRoute=$encoded';
      }
      if (hasStore) {
        // Enforce single-store invariant: already registered operators are redirected
        return resolveRoleDestination(authState.roles, returnRoute: returnRoute);
      }
      return null;
    }

    // Hard-Guarded Routes (/profile, /users)
    if (hardGuardedRoutes.contains(path)) {
      if (!isAuthenticated) {
        final encoded = Uri.encodeComponent(path);
        return '/login?returnRoute=$encoded';
      }
      return null;
    }

    // General Exploratory Routes (/home, /items, /categories, etc.)
    if (!isAuthenticated && !isGuest) {
      return '/login';
    }

    return null;
  }

  /// Creates a configured GoRouter instance with reactive auth & store state listeners.
  static GoRouter createRouter({
    AuthCubit? authCubit,
    StoreCubit? storeCubit,
    String initialLocation = '/login',
  }) {
    final effectiveAuthCubit = authCubit ??
        (singelton.isRegistered<AuthCubit>() ? singelton<AuthCubit>() : null);
    final effectiveStoreCubit = storeCubit ??
        (singelton.isRegistered<StoreCubit>() ? singelton<StoreCubit>() : null);

    Listenable? refreshListenable;
    if (effectiveAuthCubit != null && effectiveStoreCubit != null) {
      refreshListenable = GoRouterRefreshStream([
        effectiveAuthCubit.stream,
        effectiveStoreCubit.stream,
      ]);
    }

    return GoRouter(
      initialLocation: initialLocation,
      refreshListenable: refreshListenable,
      redirect: (context, state) {
        final currentAuthCubit = effectiveAuthCubit ??
            (context.mounted
                ? (() {
                    try {
                      return context.read<AuthCubit>();
                    } catch (_) {
                      return null;
                    }
                  })()
                : null);
        final currentStoreCubit = effectiveStoreCubit ??
            (context.mounted
                ? (() {
                    try {
                      return context.read<StoreCubit>();
                    } catch (_) {
                      return null;
                    }
                  })()
                : null);

        final authState = currentAuthCubit?.state ??
            AuthState(
              selectedCountry: CountryCodeModel.supportedCountries.first,
            );
        final storeState = currentStoreCubit?.state ?? const StoreInitial();

        final returnRoute = state.uri.queryParameters['returnRoute'] ??
            (state.extra is String ? state.extra as String : null);

        return evaluateRedirect(
          path: state.uri.path,
          returnRoute: returnRoute,
          authState: authState,
          storeState: storeState,
        );
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          redirect: (context, state) => '/login',
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) {
            return const LoginPage();
          },
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) {
            return const RegisterPage();
          },
        ),
        GoRoute(
          path: '/store-info',
          builder: (context, state) {
            return const StoreInfoPage();
          },
        ),
        GoRoute(
          path: '/create-store',
          builder: (context, state) {
            final returnRoute = state.extra is String
                ? state.extra as String
                : state.uri.queryParameters['returnRoute'];
            return CreateStorePage(returnRoute: returnRoute);
          },
        ),
        GoRoute(
          path: '/store/create',
          builder: (context, state) {
            return const CreateStorePage();
          },
        ),
        GoRoute(
          path: '/store/dashboard',
          builder: (context, state) {
            return const HomePage();
          },
        ),
        GoRoute(
          path: '/admin/dashboard',
          builder: (context, state) {
            return const HomePage();
          },
        ),
        GoRoute(
          path: '/delivery/orders',
          builder: (context, state) {
            return const HomePage();
          },
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) {
            return const HomePage();
          },
        ),
        GoRoute(
          path: '/items',
          builder: (context, state) {
            return const ComingSoonPage.items();
          },
        ),
        GoRoute(
          path: '/barcodes',
          builder: (context, state) {
            return const ComingSoonPage.barcodes();
          },
        ),
        GoRoute(
          path: '/categories',
          builder: (context, state) {
            return const ComingSoonPage.categories();
          },
        ),
        GoRoute(
          path: '/financial-reports',
          builder: (context, state) {
            return const ComingSoonPage.financialReports();
          },
        ),
        GoRoute(
          path: '/chart-of-accounts',
          builder: (context, state) {
            return const ComingSoonPage.chartOfAccounts();
          },
        ),
        GoRoute(
          path: '/journal',
          builder: (context, state) {
            return const ComingSoonPage.journalEntries();
          },
        ),
        GoRoute(
          path: '/transactions',
          builder: (context, state) {
            return const ComingSoonPage.transactions();
          },
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) {
            return const ComingSoonPage.dashboard();
          },
        ),
        GoRoute(
          path: '/warehouses',
          builder: (context, state) {
            return const ComingSoonPage.warehouses();
          },
        ),
        GoRoute(
          path: '/users',
          builder: (context, state) {
            return const UsersPage();
          },
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) {
            return const ProfilePage();
          },
        ),
        GoRoute(
          path: '/units',
          builder: (context, state) {
            return const ComingSoonPage.units();
          },
        ),
        GoRoute(
          path: '/invoices',
          builder: (context, state) {
            return const ComingSoonPage.invoices();
          },
        ),
        GoRoute(
          path: '/add-item',
          builder: (context, state) {
            final item = state.extra as ItemEntity?;
            return AddItemPage(item: item);
          },
        ),
        GoRoute(
          path: '/coming-soon',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is Map<String, dynamic>) {
              return ComingSoonPage(
                title: extra['title'] as String?,
                subtitle: extra['subtitle'] as String?,
                badgeText: extra['badgeText'] as String?,
                estimatedRelease: extra['estimatedRelease'] as String?,
                icon: (extra['icon'] as IconData?) ?? Icons.rocket_launch_rounded,
                previewPoints: (extra['previewPoints'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList(),
                showAppBar: (extra['showAppBar'] as bool?) ?? true,
              );
            } else if (extra is String) {
              return ComingSoonPage(
                title: extra,
                showAppBar: true,
              );
            }
            final titleParam = state.uri.queryParameters['title'];
            return ComingSoonPage(
              title: titleParam,
              showAppBar: true,
            );
          },
        ),
        GoRoute(
          path: '/updates',
          builder: (context, state) {
            return const AppUpdateScreen();
          },
        ),
        GoRoute(
          path: '/app-updates',
          builder: (context, state) {
            return const AppUpdateScreen();
          },
        ),
      ],
    );
  }

  static GoRouter? _routers;
  static GoRouter get routers => _routers ??= createRouter();
}
