import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:bokrah_retail/app/config/routes.dart';
import 'package:bokrah_retail/app/features/auth/data/models/country_code_model.dart';
import 'package:bokrah_retail/app/features/auth/presentation/cubits/auth_state.dart';
import 'package:bokrah_retail/app/features/store/presentation/cubits/store_state.dart';
import 'package:bokrah_retail/app/features/store/data/models/store_entity.dart';

void main() {
  group('Canonical Role & Return Route Resolution', () {
    test('resolves admin role to /admin/dashboard', () {
      expect(
        AppRoutes.resolveRoleDestination(['Admin']),
        equals('/admin/dashboard'),
      );
    });

    test('resolves store and retail roles to /store/dashboard', () {
      expect(
        AppRoutes.resolveRoleDestination(['Store']),
        equals('/store/dashboard'),
      );
      expect(
        AppRoutes.resolveRoleDestination(['retail']),
        equals('/store/dashboard'),
      );
    });

    test('resolves delivery role to /delivery/orders', () {
      expect(
        AppRoutes.resolveRoleDestination(['delivery']),
        equals('/delivery/orders'),
      );
    });

    test('defaults to /home for general or empty roles', () {
      expect(
        AppRoutes.resolveRoleDestination([]),
        equals('/home'),
      );
      expect(
        AppRoutes.resolveRoleDestination(['cashier']),
        equals('/home'),
      );
    });

    test('honors returnRoute when present over default role dashboard', () {
      expect(
        AppRoutes.resolveRoleDestination(['admin'], returnRoute: '/items'),
        equals('/items'),
      );
    });

    test('ignores auth routes as returnRoute and falls back to role dashboard', () {
      expect(
        AppRoutes.resolveRoleDestination(['admin'], returnRoute: '/login'),
        equals('/admin/dashboard'),
      );
      expect(
        AppRoutes.resolveRoleDestination(['admin'], returnRoute: '/register'),
        equals('/admin/dashboard'),
      );
    });
  });

  group('AppRoutes Centralized Redirection Rules', () {
    final defaultAuthState = AuthState(
      status: AuthStatus.idle,
      selectedCountry: CountryCodeModel.defaultCountry,
    );
    final guestAuthState = AuthState(
      status: AuthStatus.guest,
      selectedCountry: CountryCodeModel.defaultCountry,
    );
    final authenticatedAuthState = AuthState(
      status: AuthStatus.authenticated,
      roles: const ['store'],
      selectedCountry: CountryCodeModel.defaultCountry,
    );
    final adminAuthState = AuthState(
      status: AuthStatus.authenticated,
      roles: const ['admin'],
      selectedCountry: CountryCodeModel.defaultCountry,
    );

    const storeInitialState = StoreInitial();
    const storeLoadedWithStoreState = StoreLoaded(
      store: StoreEntity(
        id: '1',
        nameAr: 'متجر الاختبار',
        nameEn: 'Test Store',
      ),
      hasStore: true,
    );

    test('Guest visiting /login or /register is permitted', () {
      expect(
        AppRoutes.evaluateRedirect(
          path: '/login',
          authState: guestAuthState,
          storeState: storeInitialState,
        ),
        isNull,
      );
      expect(
        AppRoutes.evaluateRedirect(
          path: '/register',
          authState: guestAuthState,
          storeState: storeInitialState,
        ),
        isNull,
      );
    });

    test('Guest visiting hard-guarded /profile or /users redirects to /login with returnRoute', () {
      expect(
        AppRoutes.evaluateRedirect(
          path: '/profile',
          authState: guestAuthState,
          storeState: storeInitialState,
        ),
        equals('/login?returnRoute=%2Fprofile'),
      );
      expect(
        AppRoutes.evaluateRedirect(
          path: '/users',
          authState: guestAuthState,
          storeState: storeInitialState,
        ),
        equals('/login?returnRoute=%2Fusers'),
      );
    });

    test('Guest visiting /store-info redirects to /login with returnRoute', () {
      expect(
        AppRoutes.evaluateRedirect(
          path: '/store-info',
          authState: guestAuthState,
          storeState: storeInitialState,
        ),
        equals('/login?returnRoute=%2Fstore-info'),
      );
    });

    test('Guest visiting general route like /home or /items is permitted in read-only mode', () {
      expect(
        AppRoutes.evaluateRedirect(
          path: '/home',
          authState: guestAuthState,
          storeState: storeInitialState,
        ),
        isNull,
      );
      expect(
        AppRoutes.evaluateRedirect(
          path: '/items',
          authState: guestAuthState,
          storeState: storeInitialState,
        ),
        isNull,
      );
    });

    test('Authenticated operator without store visiting /login redirects to /store-info or returnRoute', () {
      expect(
        AppRoutes.evaluateRedirect(
          path: '/login',
          authState: authenticatedAuthState,
          storeState: storeInitialState,
        ),
        equals('/store-info'),
      );
      expect(
        AppRoutes.evaluateRedirect(
          path: '/login',
          returnRoute: '/dashboard',
          authState: authenticatedAuthState,
          storeState: storeInitialState,
        ),
        equals('/dashboard'),
      );
    });

    test('Authenticated operator without store visiting /store-info is permitted to complete onboarding', () {
      expect(
        AppRoutes.evaluateRedirect(
          path: '/store-info',
          authState: authenticatedAuthState,
          storeState: storeInitialState,
        ),
        isNull,
      );
      expect(
        AppRoutes.evaluateRedirect(
          path: '/create-store',
          authState: authenticatedAuthState,
          storeState: storeInitialState,
        ),
        isNull,
      );
    });

    test('Authenticated operator with store visiting /login or /register redirects away to role dashboard', () {
      expect(
        AppRoutes.evaluateRedirect(
          path: '/login',
          authState: authenticatedAuthState,
          storeState: storeLoadedWithStoreState,
        ),
        equals('/store/dashboard'),
      );
      expect(
        AppRoutes.evaluateRedirect(
          path: '/register',
          authState: adminAuthState,
          storeState: storeLoadedWithStoreState,
        ),
        equals('/admin/dashboard'),
      );
    });

    test('Authenticated operator with store visiting /store-info redirects away (single-store invariant)', () {
      expect(
        AppRoutes.evaluateRedirect(
          path: '/store-info',
          authState: authenticatedAuthState,
          storeState: storeLoadedWithStoreState,
        ),
        equals('/store/dashboard'),
      );
      expect(
        AppRoutes.evaluateRedirect(
          path: '/create-store',
          authState: adminAuthState,
          storeState: storeLoadedWithStoreState,
        ),
        equals('/admin/dashboard'),
      );
    });

    test('Unauthenticated user visiting / redirects to /login', () {
      expect(
        AppRoutes.evaluateRedirect(
          path: '/',
          authState: defaultAuthState,
          storeState: storeInitialState,
        ),
        equals('/login'),
      );
    });
  });

  group('GoRouterRefreshStream and createRouter', () {
    test('GoRouterRefreshStream notifies listeners on stream events', () async {
      final controller = StreamController<int>.broadcast();
      final refreshStream = GoRouterRefreshStream([controller.stream]);

      var notificationCount = 0;
      refreshStream.addListener(() {
        notificationCount++;
      });

      controller.add(1);
      await pumpEventQueue();

      expect(notificationCount, equals(1));

      controller.add(2);
      await pumpEventQueue();

      expect(notificationCount, equals(2));

      refreshStream.dispose();
      await controller.close();
    });

    test('createRouter builds a router with valid initial location', () {
      final router = AppRoutes.createRouter(initialLocation: '/login');
      expect(router.routeInformationProvider.value.uri.path, equals('/login'));
      router.dispose();
    });
  });
}
