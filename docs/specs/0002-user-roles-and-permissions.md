# User Roles & Navigation Access Control Specification

## Problem Statement

Currently, Bokrah displays all navigation sections and views indiscriminately to anyone using the client. There is no operational separation between administrative functions (such as user management and system settings), financial functions (such as general ledgers and accounting), and front-of-house sales functions (such as POS catalog and order taking). Any employee using the terminal can navigate to sensitive user records or system settings. Furthermore, user records in storage store generic role strings without active role enforcement across navigation and views.

## Solution

A simple, streamlined Role-Based Access Control (RBAC) mechanism centered around three distinct operator roles: `Admin`, `Cashier`, and `Accountant`. The active operator's role directly controls the visibility of navigation items in the main sidebar. Administrative sections are restricted exclusively to Admins, accounting sections are restricted to Admins and Accountants, while Cashiers see only the tools required for daily sales operations. When the database is newly initialized, a default Admin operator is automatically seeded to ensure zero-lockout first launch.

## User Stories

1. As a store owner (Admin), I want full access to all sections of the application (POS, Inventory, Warehouses, Users, Accounting, and Settings), so that I can configure and manage the entire business.
2. As an Admin, I want to create new operator accounts with a name, email, phone number, and a designated role (`Admin`, `Cashier`, or `Accountant`), so that staff can be onboarded with appropriate access boundaries.
3. As an Admin, I want to edit an existing operator's role and profile information, so that I can update their permissions when their job responsibilities change.
4. As an Admin, I want to deactivate an operator account without deleting historical records, so that former staff cannot log in while audit integrity is preserved.
5. As an Admin, I want to delete an operator account if it was created in error, so that the staff list remains clean.
6. As a Cashier, I want my sidebar navigation to display only sales-relevant modules (Items, Categories, and Invoices), so that I have a clean, distraction-free interface for ringing up customer orders.
7. As a Cashier, I do not want to see or access User Management or System Settings in the sidebar, so that sensitive business configurations and employee data remain protected.
8. As a Cashier, I do not want to see or access Accounting or Ledger modules, so that financial back-office operations remain confidential to management and accounting staff.
9. As an Accountant, I want access to Invoices, Accounting Playground, and catalog items in the sidebar, so that I can review invoices, reconcile accounts, and inspect ledger postings.
10. As an Accountant, I do not want to see or access User Management or System Settings in the sidebar, so that administrative control remains restricted to owners and system administrators.
11. As a store owner installing Bokrah on a fresh terminal with an empty database, I want a default Admin account automatically seeded, so that I can immediately start configuring the store without being locked out.
12. As an operator, I want my active name and assigned role badge to be clearly visible in the application interface, so that I have immediate confirmation of my active session.
13. As an operator, I want role access controls and sidebar filtering to function completely offline without requiring internet connectivity, so that daily retail operations are never interrupted by network outages.
14. As an operator switching sessions or logging in, I want the sidebar items to dynamically refresh immediately to reflect my assigned role without requiring an application restart.

## Implementation Decisions

- **Role Taxonomy**: Exactly three canonical operator roles are supported:
  - `Admin`: Unrestricted access to all views and administrative tools.
  - `Cashier`: Operational access to POS sales, Items catalog, Categories, and Invoices.
  - `Accountant`: Operational access to Invoices, Catalog (read-only), and Accounting.
- **Dynamic Navigation Filtering**: Navigation items rendered in the main sidebar are filtered against the active operator's assigned role. Sections that the operator is not authorized to access are excluded from the navigation tree.
- **Direct Domain Mapping**: Rather than introducing an indirect, multi-table permission matrix or complex override flags, allowed navigation destinations are derived directly from the active role.
- **Backward-Compatible User Persistence**: User records persist in local storage via the users service. Legacy records storing arbitrary string roles are mapped cleanly (`Admin` retains administrative access; legacy `Staff` maps to `Cashier`).
- **Initial Account Seeding**: When the users service detects zero registered operators upon initialization, it automatically creates a default Admin account.
- **Active Session State**: An observable session cubit or state provider holds the currently active operator entity and notifies UI listeners (such as the sidebar) upon login or operator change.

## Testing Decisions

- **Testing Philosophy**: Tests must exercise external user-observable behavior (such as sidebar item presence and user role updates) rather than testing internal private variables or raw storage strings.
- **High-Level Testing Seam**:
  - Primary Seam: Widget tests on the main application shell / sidebar (`HomePage` and `SidebarItem`) with a mocked or test-configured session. Verifies that passing an `Admin` operator renders all navigation items, passing a `Cashier` hides administrative and accounting sections, and passing an `Accountant` shows financial views while hiding administrative controls.
  - Secondary Seam: Service tests on `UsersService` verifying that operators are saved, updated, and retrieved with valid roles, and that default Admin seeding triggers correctly when storage is empty.
- **Prior Art**: Follows patterns established in `test/auth_flow_widget_test.dart` and `test/app_update_cubit_test.dart`.

## Out of Scope

- Fine-grained capability matrices or per-user permission checkboxes (e.g. `pos.allow_discount`).

- In-line supervisor PIN authorization dialogs or multi-user terminal switching without logout.
- Multi-branch or multi-warehouse scoping rules.
- Remote server LDAP/OAuth role synchronization.

## Further Notes

- References [ADR 0002](../adr/0002-role-based-access-control-with-permissions.md) on simple Role-Based Access Control and navigation filtering.
- Conforms to domain terminology defined in [GLOSSARY.md](../../GLOSSARY.md).
