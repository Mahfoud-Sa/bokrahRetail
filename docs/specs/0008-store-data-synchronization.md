# Store Data Synchronization

## Problem

Operational data is split between local `SharedPreferences` storage and a small
set of authenticated backend APIs. Setting `USE_MOCK_AUTH=false` does not make
catalog data remote: items, companies, categories, departments, units, and
barcodes continue to load and save locally. Data therefore cannot be shared
reliably between operators or devices using the same Store.

## Goal

Synchronize Store-owned operational data with the backend while preserving the
existing store-scoped access rules. Operators should see the active Store's
data, and changes made by one authorized operator should become available to
other operators after synchronization.

## Data scope

| Data | Current behavior | Sync intent |
| --- | --- | --- |
| Items and inventory quantities | Local preferences | Store-scoped backend records |
| Companies and brands | Local preferences | Store-scoped backend records |
| Categories and departments | Local preferences | Store-scoped backend records |
| Units and item barcodes/links | Local preferences | Store-scoped backend records, preserving item relationships |
| Invoices and sales | No complete production persistence path found | Backend contract and current feature status must be established |
| Store profile, members, roles, permissions | Existing authenticated Store APIs | Keep on existing server-owned paths; verify cache refresh on Store switch |
| Operator profile and working days | Existing profile/working-days API services | Keep on existing server-owned paths |
| App settings, auth tokens, update preferences | Device-local settings/session data | Remain local; do not sync as Store operational data |

## Required behavior

1. Every operational request is authenticated and scoped to the active Store.
2. Switching Stores must not display or mutate another Store's cached records.
3. Reads update the local cache from the server; the UI can render cached data
   while a refresh is in progress.
4. Successful writes update the cache and return the server-assigned identity
   and canonical record to the caller.
5. API errors remain visible to the caller; a failed remote write must not be
   reported as a successful save.
6. Related data keeps valid relationships when IDs are assigned by the server
   (for example item-to-category, item-to-unit, and item-to-barcode links).
7. Guest mode remains read-only and must not enqueue or send mutations.

## Implementation outline

1. Obtain and record the backend OpenAPI/schema contract for the operational
   resources, including routes, request/response DTOs, validation, pagination,
   and error shapes.
2. Confirm whether offline writes are required. If so, define an outbox,
   retry policy, idempotency keys, delete tombstones, and conflict resolution
   before implementation. `SharedPreferences` does not provide transactional
   queue semantics.
3. Establish a shared authenticated HTTP boundary that obtains the current
   token and active Store ID and maps common 401/403/network/server errors.
4. Implement remote data sources and repository synchronization per resource,
   starting with catalog entities and their dependencies.
5. Migrate existing local-only records safely, including temporary local IDs,
   without creating duplicates when a user signs in on multiple devices.
6. Add synchronization state and user-visible retry/refresh behavior where
   required by the chosen online/offline policy.

## Acceptance criteria

- A record created or changed by an authenticated operator is persisted by the
  backend for the active Store and appears after reload on another client.
- Store switching reloads the correct tenant data and prevents cross-Store
  cache leakage.
- Server validation and authorization failures are surfaced without claiming
  that data was saved.
- Existing local data is preserved or migrated according to a documented
  migration policy.
- Resource contract tests cover authenticated tenant routes, serialization,
  response parsing, and error handling.
- Arabic RTL and English UI states are usable while initial load or refresh is
  pending, and when synchronization fails.

## Open decisions and blockers

- The repository documents Store, role, and member API routes, but does not
  contain contracts for catalog, inventory, barcode, or invoice endpoints.
- The configured API's Swagger document could not be accessed from this
  environment. Backend routes and payloads must not be guessed.
- It is not yet specified whether the app must support offline writes or only
  cached reads with online-required mutations.
- Conflict policy, incremental synchronization, deletion semantics, and data
  migration need backend agreement.

