# Local Drift SQLite Database and Code Generation

## Context

Store operational data (starting with Companies and expanding across Catalog, Inventory, and Sync Outbox tables) was previously stored in `SharedPreferences` as serialized JSON lists. `SharedPreferences` does not provide transactional semantics, relational queries, or clean schema migrations needed for offline-first cloud synchronization (`0008-store-data-synchronization.md`).

## Decision

We adopt **Drift** (`drift` + `sqlite3_flutter_libs` + `path_provider` + `path`) with `drift_dev` and `build_runner` as our local SQLite database layer for Windows desktop and cross-platform builds.

- `AppDatabase` lives in `lib/app/core/database/app_database.dart` and uses `NativeDatabase.createInBackground` in production and `NativeDatabase.memory()` in unit tests.
- Local data sources (starting with `CompaniesDriftDataSource`) implement the existing feature `*LocalDataSource` interfaces so repositories and cubits remain decoupled from SQLite details.
- Existing `SharedPreferences` data is migrated on first run into Drift so no local user data is lost.
