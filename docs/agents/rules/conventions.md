# Conventions

Follow the code around you first; this file records the patterns the codebase already uses.

## Naming

- Feature folders: `snake_case` (`autoUpdate` is a legacy exception — don't rename it as a drive-by).
- Files: `snake_case.dart`. Exception: `features/barcoders/presentation/pages/addBarcoder.dart` is legacy and flagged by the analyzer; new files must be snake_case.
- Classes: `PascalCase`. Cubits end in `Cubit`, states in `State`, repositories in `Repository`/`RepositoryImpl`, data sources in `DataSource`/`Datasource` (match the folder).
- Cubit state families: `<Name>Initial`, `<Name>Loading`, `<Name>Loaded`, `<Name>Error`. Extend `Equatable` and list every field in `props` — never `[]` for a state with data.
- Use cases: verb-first (`GetAllItemsUseCase`, `SaveItemUseCase`).
- Prefer domain vocabulary from `GLOSSARY.md`.

## Imports

- Inside `lib/`, import by package: `package:bokrah_retail/app/features/...`.
- Design system: `package:bokrah_design_system/bokrah_design_system.dart`.
- Shared widgets: import `package:bokrah_retail/app/core/widgets/widgets.dart` (barrel) instead of deep paths.
- When you add a widget under `core/widgets/<category>/`, add the export to `widgets.dart` in the matching section.
- Flutter SDK imports first, then packages, then project imports (the analyzer does not enforce this, but match existing files).

## State management

- `Cubit`, not `Bloc` with events.
- Keep async work in the cubit; pages should not call services or repositories directly.
- Emit loading before an await and a terminal state after. Wrap in `try/catch` and emit `<Name>Error` with a message; do not let exceptions escape into the widget tree.
- Close cubits you create; app-global ones live for the app's lifetime.

## Localization

- Two locales: `ar` (default experience) and `en`.
- ARB sources: `lib/app/config/l10n/app_ar.arb`, `app_en.arb`.
- Generated Dart is **committed** in the same folder and there is **no `l10n.yaml`**, so `flutter gen-l10n` will not regenerate it here. Adding a string means editing the ARB *and* the corresponding `app_localizations*.dart` file — see `gotchas.md`.
- Access via `AppLocalizations.of(context)!`.
- Do not add new hardcoded Arabic or English UI strings. Existing hardcoded strings in cubit error messages are debt, not precedent.

## RTL and layout

- The app runs in both directions. Use `EdgeInsetsDirectional`, `AlignmentDirectional`, `TextAlign.start/end`, and `Row` with logical order.
- Never assume left = start.
- Test-render any layout change in Arabic if it has icons, arrows, or asymmetric padding.
- Desktop is the primary target: assume mouse and keyboard, window resizing, and wide layouts. Do not design mobile-only.

## Theming

- Use `Theme.of(context)` and design-system tokens/components. Do not hardcode `Color(0x...)`, font sizes, or paddings that the theme already exposes.
- The design system owns typography and color. If a token is missing, that is a design-system change (separate repo) — report it, don't fork the value locally.
- Support light, dark, and high contrast; don't pick colors that only work in one mode.

## Formatting and lints

- `flutter_lints` defaults via `analysis_options.yaml`; no custom rules yet.
- `dart format` before finishing. Default 80-column width.
- Do not add `// ignore:` comments to silence a real warning. Fix it or raise it.
- `flutter analyze` must stay at zero errors. Warnings are debt — don't add more.

## Errors and logging

- `avoid_print` is enabled through flutter_lints. Don't leave `print` calls; remove them or use the debug-only path already present.
- Services throw; cubits catch and translate to user-facing state.
- Never swallow an exception silently; at minimum surface an error state.

## Git

- Conventional Commits, matching history: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`.
- Scope optional, e.g. `feat(store): ...`.
- One feature or fix per commit. Do not mix formatting-only churn with behavior changes.
- Do not commit generated build output (`build/`, `dist/`, `installler/`).
