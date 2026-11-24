# Architecture

## Stack

| Concern | Choice |
| --- | --- |
| UI | Flutter 3.44 / Dart 3.12, Material 3 |
| State | `flutter_bloc` — **Cubit** only (no Event/Bloc classes in practice), `Equatable` states |
| DI | `get_it`, accessed through the global `singelton` (sic) |
| Routing | `go_router` 16, centralized in `lib/app/config/routes.dart` |
| HTTP | `http` package via feature services |
| Local storage | `shared_preferences` (items, tokens, settings) |
| Design system | external package `bokrah_design_system` (sibling repo, path dependency) |
| Localization | hand-maintained AR/EN generated classes in `lib/app/config/l10n/` |
| Scanner | `mobile_scanner` |

No database layer is active. `lib/app/core/services/app_database_service.dart` and its `.g.dart` are **entirely commented out**; the drift experiment was abandoned. Do not build on it.

## Bootstrap sequence

```
lib/main.dart
  WidgetsFlutterBinding.ensureInitialized()
  await initializationDependencies()        // GetIt registrations
  SharedPreferences.getInstance()
  PackageInfo.fromPlatform()
  runApp(MultiBlocProvider(...))
    SettingsCubit, AuthCubit, SessionCubit, RolesCubit,
    AppUpdateCubit, StoreRbacCubit, StoreCubit
    └─ BokrahRetail
         BlocBuilder<SettingsCubit>  // locale, theme, high contrast
         └─ MaterialApp.router(routerConfig: AppRoutes.routers)
```

`initializationDependencies()` lives in `lib/app/initialzation_dependencies.dart` (note the misspelling — it is the real filename). Every registration is guarded by `isRegistered<T>()`, so it is safe to call more than once.

## Directory layout

```
lib/
├── main.dart
└── app/
    ├── initialzation_dependencies.dart   # GetIt registrations
    ├── config/
    │   ├── app_config.dart               # API base URL, GitHub repo coordinates
    │   ├── routes.dart                   # GoRouter + redirect tiers + guards
    │   ├── theme.dart                    # RetailTheme light/dark from design system
    │   └── l10n/                         # ARB sources + generated localizations
    ├── core/
    │   ├── auth/app_access_guard.dart    # permission/tier checks
    │   ├── resources/data_state.dart     # unused legacy wrapper (no importers)
    │   ├── services/                     # drift leftovers (commented out)
    │   ├── usecase/usecase.dart          # callable use-case base type
    │   └── widgets/                      # shared UI, exported by widgets.dart
    └── features/
        ├── auth/  autoUpdate/  barcoders/  categories/  companies/
        ├── departments/  home/  invoices/  items/  settings/
        ├── store/  units/  users/  warehouses/
        ├── accounting_playground/  # exploratory, not production
        └── design_patterns/        # exploratory, not production
```

## Feature anatomy

A fully layered feature (use this shape for new features):

```
features/<name>/
├── data/
│   ├── datasources/     # raw storage / remote calls
│   ├── models/          # JSON <-> entity mapping
│   ├── repositories/    # <Name>RepositoryImpl implements domain interface
│   └── services/        # HTTP or mock service used by the repository
├── domain/
│   ├── entities/        # plain immutable models
│   ├── repositories/    # abstract interfaces
│   └── usecases/        # single-purpose callables
└── presentation/
    ├── cubits/          # <Name>Cubit + <Name>State
    ├── pages/           # route-level screens
    └── widgets/         # feature-local widgets
```

Reference implementation: `features/items/` (also has a local `README.md`).

Reality check — not every feature is fully layered. `auth`, `users`, `store`, `invoices`, `settings`, and `warehouses` are lighter (often `data/` + `presentation/` only, sometimes only `presentation/`). Do **not** "fix" that as a drive-by refactor. Match the feature you are in; use the full shape only for new features.

Two naming exceptions to be aware of: `autoUpdate` is camelCase, and `invoices/data/data_sources/` uses snake_case while others use `datasources/`. Follow the local folder you are editing.

## Dependency injection

All singletons are registered in `initializationDependencies()` and resolved via `singelton<T>()`.

When adding a feature:

1. Register the service/repository/cubit there, inside an `isRegistered` guard.
2. Decide mock vs real. `const useMock = bool.fromEnvironment('USE_MOCK_AUTH', defaultValue: true)` controls auth and store services. New remote services should follow the same pattern so the app still runs offline.
3. Provide the cubit at the point of use, or as a top-level `BlocProvider` in `main.dart` if it is app-global.

Do not instantiate services inside widgets.

## Routing and access control

`AppRoutes.routers` is the single source of truth (ADR-0005, spec 0006). Routes fall into tiers:

| Tier | Routes | Rule |
| --- | --- | --- |
| Public auth | `/login`, `/register` | Guests only; authenticated users are redirected to their landing page |
| Store onboarding | `/store-info`, `/create-store` | Authenticated users who have not completed onboarding |
| Hard guarded | `/profile`, `/users`, … | Authenticated + role/permission required |
| General | catalog, items, categories, … | Guests read-only; operators read/write |

Redirect is **declarative**: a top-level `redirect` callback reads `AuthCubit` and `StoreCubit` state. `GoRouterRefreshStream` bridges cubit streams to `refreshListenable`. Never redirect imperatively from a page (`context.go` after login, etc.) — that pattern was deliberately removed.

Canonical landing per role is resolved centrally. If you add a route, add it to the correct tier set in `routes.dart` and cover the redirect in a test if it is guarded.

Permissions: `core/auth/app_access_guard.dart` and `core/widgets/guards/permission_guard.dart`, backed by `StoreRbacCubit` and `RolesCubit`. Roles are `Admin`, `Cashier`, `Accountant`. Permissions are store-scoped (spec 0007): always check against the **active store**, not a global user.

## Auth and store state

- `AuthCubit` — token presence/validity, login/register/logout. Verified on startup (`checkAuthStatus`).
- `SessionCubit` — active user profile.
- `RolesCubit` — roles and permissions; loads eagerly.
- `StoreCubit` — active store profile; loads on launch when initial.
- `StoreRbacCubit` — store-scoped role/permission matrix, refreshes on store switch.

User tiers the router understands: **Guest**, **Authenticated Without Store**, **Authenticated With Store**.

## Theming and localization

`lib/app/config/theme.dart` wraps the design system: `RetailTheme.light/dark(arabic:)` and `BkTheme.highContrast`. Theme mode, contrast, and locale come from `SettingsCubit`, which persists through `SettingsLocalDataSource` (SharedPreferences).

See `conventions.md` for the rules that follow from this.
