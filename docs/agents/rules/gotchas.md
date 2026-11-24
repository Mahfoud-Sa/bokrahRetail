# Gotchas

Read this before your first command and again before claiming done.

## 1. The design system is an external sibling repo

`pubspec.yaml` declares:

```yaml
bokrah_design_system:
  path: ../../bokrah-design-system/packages/flutter
```

From the repo root, `../../` resolves to `C:\Users\mahfoud\Documents\GitHub`. The expected layout is:

```
GitHub/
├── bokrah-design-system/
│   └── packages/flutter/        <- pubspec of bokrah_design_system
└── ttemp/bokrahRetail/          <- this repo (exactly one intermediate dir)
```

If someone clones this repo directly under `GitHub/`, the path breaks. If `flutter pub get` fails with "does not exist", that is why — fix the checkout layout, do not edit the path to point at a copied package.

CI clones it separately (`.github/workflows/official.yml`). Never edit the design system from this repo; changes there ship to other apps. Report the need instead.

## 2. Mock auth is on by default

```dart
const useMock = bool.fromEnvironment('USE_MOCK_AUTH', defaultValue: true);
```

So `flutter run` uses `MockAuthService` and `MockStoreApiService`. No backend needed. For the real API:

```powershell
flutter run -d windows --dart-define=USE_MOCK_AUTH=false
```

Real API base URL: `AppConfig.apiBaseUrl`, overridable with `--dart-define=API_BASE_URL=...` (defaults to `https://jeetk-api.runasp.net`). Debugging "the data is fake" usually ends here.

## 3. Localization is hand-maintained

- ARB files: `lib/app/config/l10n/app_ar.arb`, `app_en.arb`.
- Generated Dart classes are **committed** next to them.
- There is **no `l10n.yaml`**, and `.dart_tool/flutter_gen` does not exist, so `flutter gen-l10n` will not reproduce these files in place.
- `pubspec.yaml` has `generate: true`, which is misleading — it does not currently drive this folder.

To add a string: edit the ARB **and** `app_localizations.dart`, `app_localizations_ar.dart`, `app_localizations_en.dart`. If you decide to restore generation, add `l10n.yaml` with `arb-dir`/`output-dir` pointing at `lib/app/config/l10n` and verify the output diff before committing — don't guess.

## 4. Release is Windows-only and tag-driven

Only `.github/workflows/official.yml` runs, on tags matching `v*` (or manual dispatch). It:

1. clones `bokrah-design-system`,
2. `flutter pub get`,
3. `flutter build windows --release --build-name=<tag>`,
4. builds an Inno Setup installer from `installler/setup.iss`,
5. publishes a GitHub Release.

Notes:

- `pubspec.yaml` says `1.0.0`, but the **tag** is the release source of truth (`v3.5.x` history).
- `installler/` (sic — real folder, tracked) holds `setup.iss` and `build_installer.ps1`. Do not "fix" the spelling.
- `dist/` is gitignored build output.
- There is **no CI for analyze/test**. Nothing will catch a broken push except you running the commands.
- No Android, iOS, Linux, or macOS pipeline exists. Asked to ship mobile? That is new work, not a config tweak.

## 5. `singelton` is the real name

`lib/app/initialzation_dependencies.dart` exports `final singelton = GetIt.instance;` — misspelled, used everywhere. Also note the filename misspelling (`initialzation_dependencies.dart`). Do not rename either as a drive-by; both are load-bearing across imports.

## 6. There is no database layer

`lib/app/core/services/app_database_service.dart` and `.g.dart` are commented out line by line. Drift was trialed and abandoned. Persistence today is `shared_preferences` (items, settings, tokens) plus the HTTP API. Don't import drift types, don't run `build_runner` for it.

## 7. Feature folders are not uniform

| Quirk | Example |
| --- | --- |
| camelCase feature dir | `features/autoUpdate/` |
| snake_case subfolder | `features/invoices/data/data_sources/` (others use `datasources/`) |
| non-snake_case file | `features/barcoders/presentation/pages/addBarcoder.dart` |
| layer missing entirely | `features/warehouses/` has only `presentation/` |
| no domain layer | `auth`, `users`, `store`, `invoices`, `settings` |
| exploratory code | `features/accounting_playground/`, `features/design_patterns/` |

Match the folder you are in. Don't normalize as part of an unrelated change.

## 8. Skills are duplicated and lockfile-managed

`.agents/skills/` and `.claude/skills/` both contain the same 36 skills, hashed in `skills-lock.json`. Installing or updating skills rewrites both trees. Edit skills upstream (or via the install flow), never one local copy — the next sync overwrites it.

`AGENTS.md`/`CLAUDE.md` and `docs/agents/` are the project-owned layer; those are safe to edit.

## 9. Analyzer baseline

`flutter analyze` today: **0 errors**, 31 issues (22 info, 9 warning). Known warnings you will see and should not "inherit" into new code:

- unused imports in `companies_cubit.dart`, `users_page.dart`, `store_context_switcher.dart`, `roles_management_view.dart`
- unused fields/locals in `roles_service.dart`
- unused parameter in `working_days_section.dart`

`use_build_context_synchronously` infos are widespread in older pages. New code must guard with `mounted`.

## 10. Uncommitted work is common

At the time this was written, `git status` showed in-flight work: the `companies` feature, `test/`, `core/widgets/cards/stat_metric_card.dart`, and edits to `routes.dart`, `home_page.dart`, `add_item_page.dart`. Always run `git status` before touching shared widgets, routes, or the widget barrel — you may be editing over an active branch of work.

## 11. Assorted

- `docs/api/store-api.ts` is a **TypeScript** contract snapshot for the ASP.NET Core store API. It is documentation, not app code. Read it to learn payload shapes; don't import it.
- `.metadata` was bumped by a newer Flutter and is modified in the working tree. Harmless.
- `analysis_options.yaml` has no custom rules beyond `flutter_lints`; don't add ignores to pass the gate.
- Windows line endings (`CRLF`) are the working-tree default; `git` warns on checkout. Don't reformat whole files for EOL.
