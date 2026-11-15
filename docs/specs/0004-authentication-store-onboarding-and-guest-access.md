# Authentication, Store Onboarding, and Three-Tier Access Control Specification

## Problem Statement

Users initially encountered an inconsistent onboarding experience where authentication relied on client-side mock credentials and phone-number shortcuts rather than a production-ready backend API. Unauthenticated visitors were either completely locked out or exposed to mock data, while new retail store operators had no structured pathway to register their business identity after signing up. Furthermore, the application did not distinguish between an operator who had fully established their store profile and a newly authenticated operator whose store setup was still pending, causing operations to fail unexpectedly or render incomplete data without guidance.

## Solution

A unified, backend-integrated authentication and onboarding architecture that enforces a three-tier access model:
1. **Guest**: Allows unauthenticated visitors to explore system screens and catalog layouts in read-only mode. Any attempt to perform business mutations (such as posting journal entries or saving items) is intercepted with an unobtrusive authentication prompt that preserves user workflow context.
2. **Authenticated Operator Without Store**: Once logged in, operators can navigate general features. A persistent, non-blocking setup banner guides them to complete their store profile. Actions requiring a store entity are gated until the store profile is created, while preserving any unsaved form inputs.
3. **Authenticated Operator With Store**: Upon backend confirmation of store creation, the setup banner is automatically dismissed, all retail, POS, and accounting operations are unlocked, and the store profile state is persisted across application restarts.

Client-side demo shortcuts and hardcoded credentials are completely removed in favor of authentic backend API authentication (`/api/auth/login`, `/api/auth/register`, `/api/stores`), backed by secure token persistence.

## User Stories

1. As a Guest exploring Bokrah Retail, I want to freely browse application screens, catalog items, and layouts, so that I can evaluate the software before creating an account.
2. As a Guest browsing the application, I want clear "Sign In" and "Create Account" buttons in the navigation header, so that I can authenticate at any point during my exploration.
3. As a Guest attempting to create or edit an item, I want the system to intercept the action and display a message stating "Please log in or create an account to use this feature", so that I understand why the action cannot proceed.
4. As a Guest attempting to post a journal entry or save an accounting draft, I want the system to block saving actual business data, so that financial ledgers maintain data integrity.
5. As a Guest responding to an authentication prompt, I want a direct action to log in that preserves my current location, so that I can return to my previous workflow after signing in.
6. As a store owner, I want to register a new account by providing my name, date of birth, email, password, and phone numbers, so that I can create a secure enterprise account with the Store role.
7. As a store owner registering an account, I want the system to reject registration if the email already exists or is improperly formatted, so that I receive immediate feedback on conflicting credentials.
8. As a registered operator, I want to log in using my email and password, so that I can access my account securely.
9. As an operator logging in, I want clear bilingual error messages when entering incorrect credentials, missing required fields, or attempting to access a deactivated account, so that I know how to resolve login issues.
10. As an authenticated operator, I want my authentication token and session details securely stored locally, so that I remain logged in across application restarts.
11. As an authenticated operator without a registered store, I want to see a persistent, non-intrusive banner reminding me to complete setup by adding store details, so that I am always aware of the next onboarding step.
12. As an authenticated operator without a registered store, I want to browse non-store screens without disruptive pop-up modals, so that I can explore settings and general features unhindered.
13. As an authenticated operator without a registered store attempting to perform a store-dependent operation, I want the system to prevent the operation and display "Please add your store details before continuing with this operation", so that incomplete records are not submitted.
14. As an authenticated operator encountering the store setup prompt during a task, I want my unsaved form inputs preserved, so that I do not lose my progress when I navigate to complete store registration.
15. As an authenticated operator, I want to register my single store profile with bilingual names (Arabic and English), slogan, address, Google Maps location, and contact numbers, so that my business entity is fully defined.
16. As an authenticated operator, I want the system to enforce the single-store business rule, so that an owner cannot inadvertently create duplicate store entities.
17. As an authenticated operator completing store creation, I want the persistent setup banner to disappear immediately upon backend confirmation without requiring a page reload or application restart, so that the transition feels instantaneous.
18. As an authenticated operator with a registered store, I want full, unhindered access to inventory, POS, accounting postings, and store management, so that daily operations can proceed.
19. As an operator, I want all user state prompts and banner messages fully localized in both Arabic and English with correct right-to-left layout alignment, so that the software feels native to my preferred language.
20. As a QA engineer or developer, I want all test accounts to be authentic backend accounts authenticated via standard endpoints without client-side mock bypasses or hardcoded demo credentials, so that test results accurately reflect production conditions.

## Implementation Decisions

- **Three-Tier User State Modeling**: The application access model defines three explicit operational states:
  - `guest`: No active authentication session. Read-only access to catalog and general screens.
  - `authenticatedWithoutStore`: Active token and operator session, but no registered store record. Access to general account features; gated from store-dependent mutations.
  - `authenticatedWithStore`: Active token, operator session, and confirmed store record. Full operational access.
- **Centralized Guard Module**: Access enforcement is encapsulated in a dedicated access guard providing high-level checks (`requireAuth`, `requireStore`) and standardized bilingual modal dialogs.
- **Form State Preservation**: When an operator is blocked by an onboarding gate while filling out a form, the current route and unsaved draft state are retained in the controller or navigation context, allowing the user to resume their workflow after registering the store.
- **Reactive Store State Synchronization**: The store management module exposes an observable registration status. Upon successful creation of a store entity, the state synchronizes reactively across the application tree, dismissing the setup banner and refreshing UI capabilities without requiring manual re-initialization.
- **Backend API Integration**: All authentication and registration operations interact with real JSON HTTP endpoints:
  - `POST /api/auth/register` (or `/api/auth/register/store`)
  - `POST /api/auth/login`
  - `POST /api/stores`
- **Single Store Constraint**: The client enforces and respects the one-store-per-owner backend rule (`409 Conflict`), navigating directly to the store dashboard or information view once registered.
- **Prohibition of Client-Side Demo Shortcuts**: In accordance with ADR 0003, all hardcoded quick-demo credentials and mock bypass buttons are excluded from user-facing screens, ensuring consistent security posture across debug and release builds.

## Testing Decisions

- **Testing Philosophy**: Tests must exercise user-observable behavior and navigation outcomes rather than internal state variables or private controller fields.
- **Testing Seams**:
  - **Primary Seam (Top-Level User State Flow)**: Integration widget tests mounted at the router/shell level simulating all three access tiers.
    - Verifies that a Guest can browse, sees "Sign In" / "Create Account" header actions, and receives the localized login modal upon attempting guarded operations.
    - Verifies that an authenticated operator without a store sees the persistent setup banner, is blocked with the setup dialog when attempting store mutations, and has unsaved form inputs preserved.
    - Verifies that transitioning to a registered store reactively clears the banner, emits the success confirmation, and unlocks business operations.
  - **Secondary Seam (API Client & DTO Serialization)**: Unit tests on the HTTP service layer verifying request payload structure, bearer token header injection, and accurate parsing of HTTP status responses (200, 400, 401, 409).
- **Prior Art**: Builds directly on testing patterns in `test/user_states_flow_test.dart`, `test/api_auth_service_test.dart`, `test/store_aspnet_api_test.dart`, and `test/login_flow_integration_test.dart`.

## Out of Scope

- Multi-tenant operator switching or fast PIN switching without full logout.
- Multi-branch or multi-store ownership under a single operator account.
- Social identity login providers (Google, Apple, Microsoft OAuth).
- Self-service password recovery workflows (handled via system administrator).

## Further Notes

- References [ADR 0003](../adr/0003-backend-auth-and-guest-tiering.md) on backend-driven authentication and removal of client-side demo shortcuts.
- References [ADR 0004](../adr/0004-purge-restaurant-legacy-to-retail-store.md) on complete purge of restaurant legacy layer in favor of pure retail store architecture.
- Conforms to domain terminology established in [GLOSSARY.md](../../GLOSSARY.md), specifically `Store`, `Store Profile`, `Store Onboarding`, `Operator`, `Guest`, `Role`, and `Access Level`.
