import 'package:bokrah_retail/app/features/auth/login_page.dart';
import 'package:bokrah_retail/app/features/auth/register_page.dart';
import 'package:bokrah_retail/app/features/home/home_page.dart';
import 'package:bokrah_retail/app/features/barcoders/presentation/pages/barcoders_page.dart';
import 'package:bokrah_retail/app/features/items/presentation/pages/categories_page.dart';
import 'package:bokrah_retail/app/features/items/presentation/pages/items_page.dart';
import 'package:bokrah_retail/app/features/items/presentation/pages/add_item_page.dart';
import 'package:bokrah_retail/app/features/items/data/entities/item_entity.dart';
import 'package:bokrah_retail/app/features/warehouses/presentation/pages/warehouses_page.dart';
import 'package:bokrah_retail/app/features/users/presentation/pages/users_page.dart';
import 'package:bokrah_retail/app/features/users/presentation/pages/profile_page.dart';
import 'package:bokrah_retail/app/features/restaurant/presentation/pages/restaurant_info_page.dart';
import 'package:bokrah_retail/app/features/restaurant/presentation/pages/create_restaurant_page.dart';
import 'package:bokrah_retail/app/features/units/presentation/pages/units_page.dart';
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
          return const ItemsPage();
        },
      ),
      GoRoute(
        path: '/barcodes',
        builder: (context, state) {
          return const BarcodesPage();
        },
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) {
          return const CategoriesPage();
        },
      ),
      GoRoute(
        path: '/warehouses',
        builder: (context, state) {
          return const WarehousesPage();
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
          return const UnitsPage();
        },
      ),
      GoRoute(
        path: '/add-item',
        builder: (context, state) {
          final item = state.extra as ItemEntity?;
          return AddItemPage(item: item);
        },
      ),
    ],
  );
}
