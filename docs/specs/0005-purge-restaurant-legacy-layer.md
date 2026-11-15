# Purge Restaurant Legacy Layer & Establish Pure Retail Store Architecture Specification

**Status**: `completed`

## Problem Statement

When the project was cloned from Bokrah Restaurant to Bokrah Retail, an incomplete rebranding left legacy restaurant shims, dead food graphics, and conflicting domain models throughout the application. The codebase maintained duplicate directories where an entire feature directory existed solely to re-export store classes under obsolete restaurant names. Operators were routed through `/restaurant/*` URLs, access guards enforced states named after restaurants (`authenticatedWithoutRestaurant`), and application release packages bundled hundreds of kilobytes of unreferenced food banners and restaurant logos. Furthermore, registration payloads still submitted restaurant roles and endpoints, creating confusion for developers, bloating build artifacts, and risking regressions during retail feature development.

## Solution

A clean, comprehensive purge of all restaurant legacy files, shims, assets, and routes in favor of a unified Retail Store domain model:
1. **Physical Deletion**: Completely remove all legacy restaurant export files, unused food graphics, and obsolete test shims from the repository.
2. **Domain Model Standardization**: Eradicate backward-compatibility aliases, subclasses, and dual-mode branching flags, enforcing pure `Store` entities, services, state management, and access guards across the codebase.
3. **Routing & Navigation Clean Break**: Decommission all `/restaurant/*` paths in the router so navigation operates strictly through canonical retail routes (`/store-info`, `/create-store`, `/store/dashboard`).
4. **Backend Contract Alignment**: Align registration roles and API requests strictly to retail store contracts (`POST /api/stores`, role `store`), matching the ASP.NET Core retail backend specification.
5. **Retail Localization & Verification**: Update legal copy and playground mocks to Bokrah Retail, while refactoring all existing test suites to ensure robust regression coverage under pure store names.

## User Stories

1. As a retail store owner, I want to launch the Bokrah Retail application without encountering any restaurant terminology, branding, or food imagery, so that the software feels purpose-built for my retail business.
2. As a retail store operator, I want to register a new business account using the Store role, so that my account credentials align with retail backend authorization policies.
3. As an authenticated operator without a registered store, I want to see a clear, localized banner stating "Complete your account setup by adding your store details", so that I understand my next onboarding milestone.
4. As an authenticated operator without a store, I want clicking the setup banner to navigate me directly to `/create-store`, so that I can configure my retail business identity without being redirected through deprecated URLs.
5. As an authenticated operator without a store attempting to create a retail item, I want the system to intercept the action with a store-required prompt, so that inventory records are never created without a valid store association.
6. As an authenticated operator encountering the store-required prompt while drafting an item, I want my unsaved form inputs preserved, so that I can resume item creation immediately after completing store onboarding.
7. As an authenticated operator, I want to configure my store profile with bilingual names (Arabic and English), commercial registration, tax number, currency, and warranty policies, so that my retail business entity is legally compliant.
8. As an authenticated operator, I want the system to reject duplicate store registration attempts if an entity with the same name already exists, so that business records remain unique.
9. As an authenticated operator successfully saving my store profile, I want the setup banner to dismiss reactively across the entire application without requiring a manual restart, so that the workflow is smooth and instantaneous.
10. As an authenticated operator with a registered store, I want full, unhindered access to inventory, point-of-sale, barcode scanning, accounting ledgers, and settings, so that daily store operations proceed uninterrupted.
11. As a store manager, I want to view and edit my store profile at `/store-info`, so that I can maintain updated business contact details, return windows, and warranty terms.
12. As a store cashier, I want to navigate the application dashboard at `/store/dashboard`, so that daily checkout and retail workflows operate smoothly.
13. As an unauthenticated Guest exploring the application, I want to browse catalog items, units, and system settings in read-only mode, so that I can evaluate the software before registering.
14. As an unauthenticated Guest attempting to perform accounting postings or save items, I want the system to intercept the action with a login prompt preserving my current screen, so that I can authenticate without losing context.
15. As an operator reviewing the Terms of Service during registration, I want to read retail-specific terms concerning point-of-sale transactions and store policies, so that legal expectations match retail operations.
16. As an operator exploring the accounting playground, I want sample companies and mock journal entries to reflect retail stores and retail sales transactions, so that prototypes and tutorials are relevant to retail workflows.
17. As an end user downloading or updating the application, I want the installer package to exclude dead food graphics and legacy restaurant files, so that disk space and download bandwidth are minimized.
18. As an operator navigating the application, I want deep-linked routes and navigation paths to use canonical `/store/*` paths without legacy `/restaurant/*` URLs, so that URLs are predictable and clean.
19. As a developer extending the codebase, I want all store services, cubits, DTOs, and models to use unified `Store*` naming without legacy `Restaurant*` typedefs or subclasses, so that there is no cognitive confusion.
20. As a developer running the automated test suite, I want all test cases to test `Store*` modules directly using retail test descriptors, so that test reports accurately communicate system capabilities.

## Implementation Decisions

- **Complete Deletion of Legacy Restaurant Shim Layer**: Remove the entire legacy restaurant directory structure and proxy widgets. All code and test suites previously importing restaurant shims must import the corresponding store modules directly.
- **Pure Retail Domain Architecture**:
  - Strip all backward-compatibility subclasses (`CreateRestaurantRequest`), type aliases (`RestaurantEntity`, `RestaurantResponse`, `RestaurantCubit`, `RestaurantReceiptPreview`), and helper bridges.
  - Remove all conditional `isRestaurant` boolean flags and dual-mode UI branches from store creation and store info screens, standardizing strictly on retail store fields (e.g., Commercial Registration, Tax Number, Warranty Policy, Return Policy).
- **Access Control & State Guard Harmonization**:
  - Standardize application user state enums strictly on `guest`, `authenticatedWithoutStore`, and `authenticatedWithStore`. Remove `authenticatedWithoutRestaurant`.
  - Harmonize access guard methods to `requireStore()` and `requireAuth()`, removing legacy `requireRestaurant()` methods and restaurant notice strings.
- **Routing & Navigation Clean Break**:
  - Remove all deprecated `/restaurant/*` routes (`/restaurant-info`, `/create-restaurant`, `/restaurant/create`, `/restaurant/add`, `/restaurant/dashboard`) from the application routing table.
  - Ensure canonical routes `/store-info`, `/create-store`, and `/store/dashboard` directly bind to retail store view components.
- **Backend API & Payload Contract Alignment**:
  - Standardize API client endpoint bindings strictly on `POST /api/stores` with authorization role `store`.
  - Remove obsolete `/api/restaurants` and `/api/auth/register/restaurant` endpoint paths.
  - Standardize store and auth session models on retail role parsing (`Store`, `Admin`, `Cashier`, `Accountant`).
- **Asset Bundle Optimization**:
  - Permanently remove unused food images and restaurant logos from the assets directory to eliminate dead weight from application builds and installers.
- **Localization & Copy Modernization**:
  - Update localized legal agreements and Terms of Service copy in localization files to describe retail point-of-sale, warranty management, and inventory operations.
  - Update mock company names and demo journal entries in prototype modules to retail store data.

## Testing Decisions

- **Testing Philosophy**: Tests must exercise user-observable behavior, router navigation outcomes, and access state transitions rather than private controller states or internal variable bindings.
- **Testing Seams**:
  - **Primary Seam (Router & Application Shell Integration Seam)**:
    - Mount tests at the root application router level (`MaterialApp.router` with `AppRoutes.routers`).
    - Verify that an unauthenticated Guest can browse the catalog and is prompted to sign in when attempting guarded store mutations.
    - Verify that an authenticated operator without a store sees the persistent retail setup banner, is gated when attempting store mutations with input preservation, and navigates seamlessly to `/create-store`.
    - Verify that completing store registration dismisses the banner, unlocks full retail operations, and persists store state locally across sessions.
  - **Secondary Seam (Store API Client & DTO Serialization Seam)**:
    - Unit and integration tests on the HTTP store service layer verifying request payload construction, bearer token header injection, and HTTP status handling (201, 400, 401, 409) for `POST /api/stores`.
- **Prior Art**: Builds directly on testing patterns in `test/store_aspnet_api_test.dart`, `test/user_states_flow_test.dart`, and `test/guest_user_scenarios_test.dart`.

## Out of Scope

- Multi-store or multi-branch switching under a single operator login.
- Modifying backend ASP.NET Core server endpoints or remote database schemas.
- Modifying ZATCA electronic invoice XML/QR-code generation algorithms.

## Further Notes

- Implements the architectural direction formalized in [ADR 0004](../adr/0004-purge-restaurant-legacy-to-retail-store.md).
- Adheres strictly to the canonical retail terms defined in [GLOSSARY.md](../../GLOSSARY.md), specifically `Store`, `Store Profile`, `Store Onboarding`, `Operator`, `Guest`, and `Role`.
