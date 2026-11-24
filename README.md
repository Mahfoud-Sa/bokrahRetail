# Bokrah Retail

Point-of-sale, inventory, and retail management desktop app for shops, consumer electronics, and general retail.

Arabic-first and bilingual (AR/EN), RTL-aware, Windows-first with Android, iOS, Linux, and macOS scaffolding.

## Stack

Flutter 3.44 · Dart 3.12 · Material 3 · `flutter_bloc` (Cubit) · `go_router` · `get_it` · `shared_preferences` · `mobile_scanner` · [`bokrah_design_system`](https://github.com/Mahfoud-Sa/bokrah-design-system)

## Requirements

- Flutter stable (3.44+) with Windows desktop enabled
- Visual Studio 2022 with the "Desktop development with C++" workload (Flutter Windows builds)
- Inno Setup 6, only if you build the installer locally

## Setup

`bokrah_design_system` is a **path dependency**, not a published package. The repo must sit exactly one directory away from it:

```
<workspace>/
├── bokrah-design-system/
└── ttemp/bokrahRetail/      <- this repo
```

Clone both, then:

```powershell
cd ttemp/bokrahRetail
flutter pub get
```

If `pub get` reports the design system path is missing, fix the directory layout — do not repoint the dependency at a copy.

## Run

```powershell
flutter run -d windows
```

Runs fully offline against mock auth and a mock store API.

To use the real backend:

```powershell
flutter run -d windows --dart-define=USE_MOCK_AUTH=false
```

Override the API host if needed:

```powershell
flutter run -d windows --dart-define=API_BASE_URL=https://your-host
```

## Verify

```powershell
flutter analyze
flutter test
```

The analyzer currently reports 0 errors and 31 info/warning issues; tests are green. Both must stay that way.

## Build & release

```powershell
flutter build windows --release
```

Releases are produced by GitHub Actions on `v*` tags: it checks out the design system, builds the Windows app, wraps it with Inno Setup (`installler/setup.iss`), and publishes a GitHub Release. The tag drives the version — `pubspec.yaml`'s version is not the release source of truth.

Manual installer build:

```powershell
.\installler\build_installer.ps1
```

## Project layout

```
lib/
├── main.dart
└── app/
    ├── initialzation_dependencies.dart   # GetIt registrations
    ├── config/                           # routes, theme, API config, l10n
    ├── core/                             # guards, shared widgets, use-case base
    └── features/                         # one folder per business area
```

Features are Clean-Architecture-shaped where it earns its keep: `data/` → `domain/` → `presentation/`. `features/items/` is the reference implementation.

## Documentation

- [`AGENTS.md`](AGENTS.md) — entry point for AI agents and contributors
- [`GLOSSARY.md`](GLOSSARY.md) — domain vocabulary (read before naming anything)
- [`docs/adr/`](docs/adr/) — architecture decision records
- [`docs/specs/`](docs/specs/) — numbered feature specs
- [`docs/agents/`](docs/agents/) — agent rules, issue tracker conventions, testing

## Contributing

Conventional Commits. One feature or fix per branch. Run `flutter analyze` and `flutter test` before opening a PR. Never edit the design system from this repo.
