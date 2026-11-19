# Store Management & Store-Scoped RBAC Frontend Integration Specification

## Problem Statement

As retail businesses grow and onboard multiple operators across branches, store owners and managers need to delegate daily operational duties—such as handling cash registers, managing catalog items, reviewing purchase bills, or onboarding store members—without exposing high-risk administrative capabilities or sensitive financial records.

Currently, the client application relies on static, generic role strings with no granular operational delegation. Operators across different stores either possess blanket administrative access or are severely restricted, with no mechanism to assign custom duty-specific responsibilities (such as inventory supervisor or cashier). Furthermore, when store operations are executed:
- The frontend lacks a standardized contract to query available system capabilities or reflect dynamic custom roles configured on the backend.
- Legal store owners risk being inadvertently locked out of administrative tasks if their operator accounts are not assigned a specific role name.
- Client applications have to guess permissions through brittle role name comparisons rather than inspecting an authoritative list of granted operational capabilities.
- Error handling around store scoping, missing permissions, and member provisioning is inconsistent, leading to confusing user experiences when operations are rejected with authorization errors.

## Solution

A comprehensive store-scoped Role-Based Access Control (RBAC) integration architecture for the frontend client that decouples high-level store membership from granular operational entitlements:
1. **Dynamic Permission Catalog**: The client fetches an authoritative catalog of atomic permissions grouped by operational categories (Orders, Finance, Members, Roles, Settings, Analytics) to dynamically render role creation and assignment interfaces.
2. **Custom Store Roles**: Store owners and authorized managers can create, update, and manage custom roles within their active store tenant, selecting exact combinations of atomic permissions.
3. **Implicit Owner Superuser Rights**: Legal store owners automatically receive implicit superuser rights and catalog capabilities across their store, ensuring zero-lockout operation regardless of custom role naming.
4. **Effective Permissions as Single Source of Truth**: Backend member payloads provide a flat array of granted capability strings (`effectivePermissions`). The frontend evaluates user access exclusively against this array via declarative permission guards and helper utilities, eliminating hardcoded role string heuristics.
5. **Store-Scoped Tenancy**: Every operational request is tied to an active store context, allowing seamless store switching and dynamic context refresh for operators managing or working across multiple retail locations.

## User Stories

1. As a store owner, I want to view a catalog of all available system permissions grouped by business categories, so that I can understand what capabilities can be delegated to my store members.
2. As a store owner, I want to create custom store roles with descriptive names and specific permission sets, so that I can tailor operational access to my store's exact staffing structure.
3. As a store owner, I want to view a list of all custom roles defined for my active store, including their assigned permissions and member counts, so that I can audit role configurations.
4. As a store owner, I want to update an existing custom role's name, description, and permission codes, so that I can adapt role duties as store workflows evolve.
5. As a store owner, I want to delete an unused custom role, so that the store's role list remains organized and clutter-free.
6. As a store owner, I want implicit superuser rights over all my store's resources, so that I am never locked out of managing roles, members, or settings.
7. As a store owner, I want to view all store members assigned to my store along with their active roles and effective permissions, so that I have complete operational oversight.
8. As a store owner, I want to provision a new store member by email, password, and custom role IDs in a single operation, so that onboarding new team members is fast and frictionless.
9. As a store owner, I want the system to link an existing registered user to my store when provisioning with their registered email, so that users do not have to maintain multiple login accounts.
10. As a store owner, I want to assign multiple custom roles to a store member, so that employees with cross-functional responsibilities inherit all necessary permissions.
11. As a store owner, I want to update a store member's assigned roles, so that changes in their responsibilities immediately update their effective permissions.
12. As a store owner, I want to remove a store member from my store, so that former personnel cannot access store records or perform transactions.
13. As a store owner, I want the system to prevent removing the sole remaining owner of a store, so that the store is never left without administrative ownership.
14. As an operator holding delegated member management permissions, I want to invite and assign roles to other store members, so that I can assist with store staffing without requiring full store ownership.
15. As an operator holding delegated role management permissions, I want to view and create store roles, so that I can configure operational permissions for the team.
16. As an operator lacking role management permissions, I want role creation and editing controls to be hidden or disabled in the UI, so that I am not exposed to unauthorized operations.
17. As an operator lacking member management permissions, I want member provisioning and deletion buttons to be hidden in the UI, so that sensitive team changes remain restricted to authorized leaders.
18. As an operator, I want my active store session to compute my effective permissions from my assigned roles, so that client views adapt dynamically to my exact access level.
19. As an operator working across multiple retail branches, I want to view a list of all stores where I hold membership, so that I can select and switch between them easily.
20. As an operator switching active stores, I want my navigation options, permissions, and visible data to refresh immediately to reflect my role in the selected store, so that I never act on outdated tenant permissions.
21. As an operator encountering an authorization failure (403 Forbidden), I want to see a clear, descriptive message indicating insufficient permissions, so that I understand why the operation was rejected.
22. As an operator attempting an action with an expired session (401 Unauthorized), I want the client to redirect me cleanly to sign in, so that I can re-authenticate without application crashes.
23. As a store owner updating store profile information, I want changes to persist reliably under the active store identifier, so that legal and tax details remain accurate.
24. As an operator, I want all store management operations to validate required fields and duplicate names locally and display backend validation errors directly on form inputs, so that I can correct input mistakes immediately.

## Implementation Decisions

- **Domain Terminology Alignment**: All entities, contracts, and UI labels adhere strictly to canonical terms defined in the domain glossary. Personnel working within a retail store are designated as "Store Members" or "Operators"; the forbidden terminology "Staff" / "staff members" is excluded from all client models and contracts.
- **Two-Tier Authorization Model**:
  - *Tier 1 (Store Owner)*: The operator matching the store's legal owner identifier automatically receives full superuser access and implicitly inherits all capability codes in the permission catalog.
  - *Tier 2 (Delegated Store Members)*: Operational access is determined strictly by evaluating the atomic permission codes contained within the operator's `effectivePermissions` list.
- **Single Source of Truth for Client Entitlements**: The client application does not derive permissions by parsing or matching role name strings (e.g., checking if `role == 'Manager'`). Instead, authorization checks evaluate the presence of specific capability codes (e.g., `effectivePermissions.contains('store.roles.manage')`) returned directly by the store membership endpoints.
- **Declarative UI Permission Guards**: A reusable permission guard component wraps actionable UI elements (buttons, forms, navigation tabs). Elements requiring specific capabilities are rendered conditionally when the active operator is the store owner or possesses the required atomic code; unauthorized elements are cleanly excluded from the widget tree or replaced with an disabled fallback state.
- **Store Tenancy Context**: Store-scoped REST endpoints incorporate the active store identifier directly in the URL route path (`/api/stores/{storeId}/...`). The client application maintains an observable store context that supplies the current store identifier and reloads members, roles, and effective permissions whenever the active store changes.
- **Unified Member Provisioning Contract**: The member provisioning flow accepts an email address, full name, temporary password, and a list of custom role identifiers. The client handles the response by refreshing the store member list and displaying immediate confirmation of assigned roles.
- **Structured Error Handling Hierarchy**: API error responses map to dedicated exception types:
  - `401 Unauthorized`: Triggers automatic session teardown and navigation to the sign-in route.
  - `403 Forbidden`: Triggers a non-intrusive warning notification indicating insufficient operational permissions.
  - `404 Not Found`: Displays a tenant/resource not found state and prompts store reselection.
  - `409 Conflict`: Maps backend conflict messages (e.g., duplicate role names or duplicate member assignment) directly to input validation states.
  - `400 Bad Request`: Extracts field-level validation errors to display inline under corresponding form inputs.

## Testing Decisions

- **Testing Philosophy**: Tests must exercise user-observable behavior and external boundaries rather than private implementation details. We verify what the operator sees and can do based on granted capabilities.
- **Primary Testing Seam**:
  - *UI Presentation & Permission Guard Boundary*: Widget tests on store management views (e.g. `StoreRolesPage`, `StoreMembersPage`, and `PermissionGuard`) injected with varying member profiles. Tests verify that an owner or an operator with `store.roles.manage` can see and trigger role creation dialogs, while an operator with only read-only or unrelated permissions sees only viewing interfaces with management controls hidden.
- **Secondary Testing Seam**:
  - *Store API Client Service Boundary*: Contract tests on the API service layer verifying that HTTP requests include proper tenant route paths (`/api/stores/{storeId}/...`), correct serialization of payload fields (`roleIds`), and accurate deserialization of `effectivePermissions` and error responses.
- **Prior Art**: Follows established testing conventions in `test/router_redirection_test.dart` and existing cubit state verification tests.

## Out of Scope

- Central multi-organization billing or subscription tiers.
- Cross-store global super-administrator screens outside retail store boundaries.
- Offline optimistic queueing for member and role mutations (store RBAC mutations require active network connectivity to ensure consistent access control).
- Biometric or multi-factor authentication enforcement per store role.

## Further Notes

- The permission catalog is dynamic and server-driven (`GET /api/stores/permissions/catalog`). The frontend should cache the catalog per session but avoid hardcoding category structures, allowing backend modules to add new operational permissions without requiring mobile or web client updates.
- Store switching must reset any active member/role editing states to prevent accidental cross-tenant mutation.
