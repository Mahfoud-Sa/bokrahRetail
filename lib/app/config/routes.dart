import 'package:flutter/material.dart';
import 'package:bokrah_retail/app/features/auth/login_page.dart';
import 'package:bokrah_retail/app/features/auth/register_page.dart';
import 'package:bokrah_retail/app/features/home/home_page.dart';
import 'package:bokrah_retail/app/features/items/presentation/pages/add_item_page.dart';
import 'package:bokrah_retail/app/features/items/data/entities/item_entity.dart';
import 'package:bokrah_retail/app/features/users/presentation/pages/users_page.dart';
import 'package:bokrah_retail/app/features/users/presentation/pages/profile_page.dart';
import 'package:bokrah_retail/app/features/restaurant/presentation/pages/restaurant_info_page.dart';
import 'package:bokrah_retail/app/features/restaurant/presentation/pages/create_restaurant_page.dart';
import 'package:bokrah_retail/app/features/common/presentation/pages/coming_soon_page.dart';
import 'package:go_router/go_router.dart';


class AppRoutes {
  static final GoRouter routers = GoRouter(
    initialLocation: '/login',
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
          return const RestaurantInfoPage();
        },
      ),
      GoRoute(
        path: '/create-store',
        builder: (context, state) {
          final returnRoute = state.extra is String
              ? state.extra as String
              : state.uri.queryParameters['returnRoute'];
          return CreateRestaurantPage(returnRoute: returnRoute);
        },
      ),
      GoRoute(
        path: '/store/create',
        builder: (context, state) {
          return const CreateRestaurantPage();
        },
      ),
      GoRoute(
        path: '/store/dashboard',
        builder: (context, state) {
          return const HomePage();
        },
      ),
      GoRoute(
        path: '/restaurant-info',
        builder: (context, state) {
          return const RestaurantInfoPage();
        },
      ),
      GoRoute(
        path: '/create-restaurant',
        builder: (context, state) {
          final returnRoute = state.extra is String
              ? state.extra as String
              : state.uri.queryParameters['returnRoute'];
          return CreateRestaurantPage(returnRoute: returnRoute);
        },
      ),
      GoRoute(
        path: '/restaurant/create',
        builder: (context, state) {
          return const CreateRestaurantPage();
        },
      ),
      GoRoute(
        path: '/restaurant/add',
        builder: (context, state) {
          return const CreateRestaurantPage();
        },
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) {
          return const HomePage();
        },
      ),
      GoRoute(
        path: '/restaurant/dashboard',
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
        path: '/admin/dashboard',
        builder: (context, state) {
          return const HomePage();
        },
      ),
      GoRoute(
        path: '/restaurant/dashboard',
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
    ],
  );
}
