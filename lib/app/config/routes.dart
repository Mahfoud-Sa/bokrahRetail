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
import 'package:bokrah_retail/app/features/items/presentation/pages/item_details_page.dart';
import 'package:bokrah_retail/app/features/items/presentation/pages/items_page.dart';
import 'package:bokrah_retail/app/features/departments/presentation/pages/departments_page.dart';
import 'package:bokrah_retail/app/features/categories/presentation/pages/categories_page.dart';
import 'package:bokrah_retail/app/features/items/domain/entities/item_entity.dart';
import 'package:bokrah_retail/app/features/users/presentation/pages/users_page.dart';
import 'package:bokrah_retail/app/features/users/presentation/pages/profile_page.dart';
import 'package:bokrah_retail/app/features/store/presentation/pages/store_info_page.dart';
import 'package:bokrah_retail/app/features/store/presentation/pages/create_store_page.dart';
import 'package:bokrah_retail/app/core/widgets/pages/coming_soon_page.dart';
import 'package:bokrah_retail/app/features/autoUpdate/presentation/app_update_screen.dart';
import 'package:bokrah_retail/app/initialzation_dependencies.dart';

/// Reactive [Listenable] bridge that translates multiple asynchronous BLoC/Cubit
/// broadcast streams into synchronous notifications for [GoRouter].
///
/// **Why this is needed:**
/// [GoRouter] expects a synchronous [Listenable] (like [ChangeNotifier]) via its
/// `refreshListenable` parameter to know when to re-run top-level `redirect` checks.
/// Since [AuthCubit] and [StoreCubit] expose asynchronous [Stream] instances,
/// this class subscribes to each stream and calls [notifyListeners] whenever
/// authentication status, roles, or store registration state changes.
///
/// **Lifecycle:**
/// Subscriptions are actively tracked in [_subscriptions] and properly cancelled
/// when [dispose] is called, preventing memory leaks and dangling stream listeners.
class GoRouterRefreshStream extends ChangeNotifier {
  late final List<StreamSubscription<dynamic>> _subscriptions;

  /// Creates a [GoRouterRefreshStream] that listens to each provided [Stream].
  ///
  /// Streams are converted to broadcast streams if needed to support multiple
  /// listeners without throwing state errors.
  GoRouterRefreshStream(List<Stream<dynamic>> streams) {
    _subscriptions = streams
        .map((stream) => stream.asBroadcastStream().listen((_) => notifyListeners()))
        .toList();
  }

  /// Cancels all active stream subscriptions and releases resources.
  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}

/// Central routing configuration and access control manager for Bokrah Retail.
///
/// Implements declarative route tiering and redirection rules per ADR 0005 and
/// Specification 0006. Routes are grouped into four distinct categories:
/// 1. [publicAuthRoutes]: Strictly unauthenticated access (/login, /register).
/// 2. [storeOnboardingRoutes]: First-time business setup (/store-info, /create-store).
/// 3. [hardGuardedRoutes]: Operator/Admin-only settings (/profile, /users).
/// 4. General Exploratory Routes: Read-only catalog browsing for Guests, full
///    access for authenticated operators.
class AppRoutes {
  /// Routes reserved exclusively for unauthenticated visitors and guests.
  /// Authenticated operators navigating here are automatically redirected away.
  static const Set<String> publicAuthRoutes = {'/login', '/register'};

  /// Routes reserved for authenticated operators who have not yet configured
  /// their store profile. Unauthenticated visitors are redirected to sign-in,
  /// while operators who already have a registered store are redirected to their
  /// dashboard to strictly enforce the single-store invariant.
  static const Set<String> storeOnboardingRoutes = {
    '/store-info',
    '/create-store',
    '/store/create',
  };

  /// Routes that strictly require an authenticated operator session.
  /// Guests navigating here are automatically redirected to /login with their
  /// target location preserved via the `returnRoute` query parameter.
  static const Set<String> hardGuardedRoutes = {'/profile', '/users'};

  /// Resolves the default landing page destination after successful sign-in.
  ///
  /// Prioritizes:
  /// 1. An existing, valid [returnRoute] (ignoring /login or /register loops).
  /// 2. Administrator role (`admin`) -> `/admin/dashboard`
  /// 3. Store/Retail operator role (`store`, `retail`) -> `/store/dashboard`
  /// 4. Delivery operator role (`delivery`) -> `/delivery/orders`
  /// 5. Fallback for general operators -> `/home`
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
  ///
  /// Evaluates the current navigation request against the active [AuthState] and
  /// [StoreState] without relying on BuildContext or mounted widget state:
  ///
  /// - Returns a `String` route path when redirection is required.
  /// - Returns `null` when navigation to the requested [path] is permitted.
  static String? evaluateRedirect({
    required String path,
    String? returnRoute,
    required AuthState authState,
    required StoreState storeState,
  }) {
    final isGuest = authState.status == AuthStatus.guest;
    final isAuthenticated = authState.status == AuthStatus.authenticated;
    final hasStore = storeState is StoreLoaded && storeState.hasStore;

    // 1. Root location ('/'): Route to login if unauthenticated, onboarding if
    // store is missing, or the role dashboard if fully configured.
    if (path == '/') {
      if (!isAuthenticated) return '/login';
      if (!hasStore) return '/store-info';
      return resolveRoleDestination(authState.roles, returnRoute: returnRoute);
    }

    // 2. Public Auth Routes (/login, /register): Visitors and guests are allowed.
    // Authenticated operators are bounced away to their role destination or onboarding.
    if (publicAuthRoutes.contains(path)) {
      if (!isAuthenticated) {
        return null;
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

    // 3. Store Onboarding Routes (/store-info, /create-store, /store/create):
    // Guests must sign in first. Operators with an existing store are bounced away
    // to prevent duplicate store registrations (HTTP 409 Conflict).
    if (storeOnboardingRoutes.contains(path)) {
      if (!isAuthenticated) {
        final encoded = Uri.encodeComponent(path);
        return '/login?returnRoute=$encoded';
      }
      if (hasStore) {
        return resolveRoleDestination(authState.roles, returnRoute: returnRoute);
      }
      return null;
    }

    // 4. Hard-Guarded Routes (/profile, /users):
    // Guests have no profile or administrative data, so they are redirected to /login
    // with their intended path preserved in `returnRoute`.
    if (hardGuardedRoutes.contains(path)) {
      if (!isAuthenticated) {
        final encoded = Uri.encodeComponent(path);
        return '/login?returnRoute=$encoded';
      }
      return null;
    }

    // 5. General Exploratory Routes (/home, /items, /categories, etc.):
    // Completely unauthenticated requests (neither logged in nor in Guest mode)
    // are directed to sign in. Guests and operators are permitted.
    if (!isAuthenticated && !isGuest) {
      return '/login';
    }

    return null;
  }

  /// Creates a configured [GoRouter] instance with reactive authentication and store listeners.
  ///
  /// **Dependency Resolution:**
  /// - Accepts optional [authCubit] and [storeCubit] parameters for isolated testing.
  /// - Falls back to GetIt [singelton] instances when running in the full application harness.
  /// - Dynamically resolves cubits from [BuildContext] if singletons are not yet registered.
  ///
  /// **Redirection Engine:**
  /// Re-evaluates [evaluateRedirect] synchronously on route change or whenever either
  /// cubit emits a new state via [GoRouterRefreshStream].
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
            return const ItemsPage();
          },
        ),
        GoRoute(
          path: '/barcodes',
          builder: (context, state) {
            return const ComingSoonPage.barcodes();
          },
        ),
        GoRoute(
          path: '/departments',
          builder: (context, state) {
            return const DepartmentsPage();
          },
        ),
        GoRoute(
          path: '/categories',
          builder: (context, state) {
            return const CategoriesPage();
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
            ItemEntity? item;
            int? deptId;
            int? catId;
            final extra = state.extra;
            if (extra is ItemEntity) {
              item = extra;
            } else if (extra is Map) {
              if (extra['item'] is ItemEntity) {
                item = extra['item'] as ItemEntity;
              }
              if (extra['departmentId'] is int) {
                deptId = extra['departmentId'] as int;
              }
              if (extra['categoryId'] is int) {
                catId = extra['categoryId'] as int;
              }
            }
            return AddItemPage(
              item: item,
              initialDepartmentId: deptId,
              initialCategoryId: catId,
            );
          },
        ),
        GoRoute(
          path: '/item-details',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is ItemEntity) {
              return ItemDetailsPage(item: extra);
            }
            if (extra is Map<String, dynamic>) {
              return ItemDetailsPage(
                item: extra['item'] as ItemEntity,
                departmentName: extra['departmentName'] as String?,
                categoryPath: extra['categoryPath'] as String?,
                baseUnitName: extra['baseUnitName'] as String?,
              );
            }
            return const Scaffold(
              body: Center(child: Text('العنصر غير موجود')),
            );
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

  /// Lazy singleton instance of [GoRouter] configured for the application.
  /// Uses dependency injection defaults registered in [initializationDependencies].
  static GoRouter get routers => _routers ??= createRouter();
}

