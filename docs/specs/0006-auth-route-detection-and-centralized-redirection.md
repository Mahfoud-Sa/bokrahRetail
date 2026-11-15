# Authentication Route Detection and Centralized Redirection Specification

## Problem Statement

Users and operators currently experience inconsistent and fragmented navigation behavior across the application. Redirection logic after signing in or registering is scattered across imperative post-frame callbacks and widget listeners inside individual screens, while the central router lacks awareness of user access tiers and store onboarding progress. Consequently:
- Unauthenticated visitors (Guests) navigating directly or via deep links to protected screens (such as profile settings or operator management) encounter broken or uninitialized views instead of a clean, context-preserving sign-in prompt.
- Authenticated operators who have already established their store profile can still navigate back to store onboarding and registration forms, introducing confusion and triggering backend conflict errors upon resubmission.
- Newly registered operators are not consistently guided through store onboarding before attempting store-dependent operations.
- Operators logging in from a guarded prompt lose their initiated workflow because destination paths (`returnRoute`) are not systematically captured, preserved, or restored by the routing layer.

## Solution

A centralized, reactive router architecture that detects and categorizes all authentication and onboarding routes and enforces declarative redirection rules directly within the application router. The router observes operator authentication state and store profile status through a unified reactive stream, automatically evaluating route eligibility before page widgets mount:
1. **Public Auth Routes** (`/login`, `/register`) are reserved for Guests and unauthenticated users; authenticated operators are automatically redirected away to their role-specific dashboard or pending store onboarding.
2. **Store Onboarding Routes** (`/store-info`, `/create-store`) are reserved for authenticated operators lacking a store entity; visitors are directed to sign in, while established store owners are directed to their dashboard.
3. **Hard-Guarded Routes** (`/profile`, `/users`) immediately redirect Guests to the sign-in page with their intended destination preserved in a query parameter (`/login?returnRoute=<path>`), seamlessly restoring their route after authentication.
4. **General Exploratory Routes** remain freely browsable in read-only mode for Guests, while authenticated operators without a store are supported through non-intrusive onboarding banners rather than disruptive routing traps.

## User Stories

1. As an unauthenticated Guest browsing the system, I want to freely explore public catalog and overview screens in read-only mode, so that I can evaluate the software before creating an account.
2. As an unauthenticated Guest attempting to access my profile settings (`/profile`), I want the router to redirect me directly to the sign-in screen, so that I understand authentication is required to access personal profile data.
3. As an unauthenticated Guest attempting to access operator management (`/users`), I want the router to redirect me to the sign-in screen, so that administrative tools are protected from unauthorized viewing.
4. As an unauthenticated Guest redirected to the sign-in screen from a guarded route, I want my intended destination preserved in the URL query parameters (`/login?returnRoute=...`), so that I can resume my intended task immediately upon logging in.
5. As an unauthenticated Guest attempting to directly access store onboarding (`/store-info`), I want the router to redirect me to the sign-in screen with the onboarding return route preserved, so that I first authenticate an operator identity before configuring a store.
6. As an unauthenticated Guest attempting to directly access standalone store creation (`/create-store`), I want the router to redirect me to the sign-in screen, so that store entities cannot be provisioned without an authenticated owner.
7. As an unauthenticated visitor, I want direct, unhindered access to the sign-in screen (`/login`), so that I can authenticate with my credentials or choose to continue as a Guest.
8. As an unauthenticated visitor, I want direct, unhindered access to the registration screen (`/register`), so that I can create a new store owner account.
9. As an authenticated operator with an active store profile, I want the router to automatically redirect me away from `/login` to my designated dashboard, so that I am not prompted to sign in again while already authenticated.
10. As an authenticated operator with an active store profile, I want the router to automatically redirect me away from `/register` to my dashboard, so that I do not accidentally attempt to create duplicate operator accounts.
11. As an authenticated operator with an active store profile, I want the router to redirect me away from store onboarding (`/store-info`) to my store dashboard, so that I do not re-run onboarding for an already registered store.
12. As an authenticated operator with an active store profile, I want the router to redirect me away from standalone store creation (`/create-store`) to my dashboard, so that the single-store business constraint is strictly maintained.
13. As an authenticated administrator, I want successful login without a return route to navigate me directly to the administrative dashboard (`/admin/dashboard`), so that I can access system administration tools immediately.
14. As an authenticated store operator, I want successful login without a return route to navigate me directly to the retail store dashboard (`/store/dashboard`), so that I can begin point-of-sale and inventory operations without unnecessary clicks.
15. As an authenticated delivery operator, I want successful login without a return route to navigate me directly to the delivery order management view (`/delivery/orders`), so that I can manage assigned dispatches promptly.
16. As an authenticated operator of any general role, I want successful login without a return route to navigate me to the main home workspace (`/home`), so that I have a consistent landing baseline.
17. As an authenticated operator logging in with a valid `returnRoute` parameter, I want the router to take me directly to that specified return destination rather than the default role dashboard, so that my prior workflow is seamlessly restored.
18. As a newly registered store owner transitioning from account creation, I want the system to route me smoothly to store onboarding (`/store-info`), so that I can complete business registration details.
19. As an authenticated operator whose store profile is not yet created, I want to freely view general system screens without being forcibly trapped on the onboarding screen, so that I can explore features comfortably while seeing a non-intrusive setup banner.
20. As an authenticated operator without a store entity attempting to perform a store-dependent action, I want clear redirection or modal guidance to `/store-info`, so that I know exactly how to unblock business operations.
21. As an operator logging out of the application, I want the router to reactively transition my view to the sign-in screen (`/login`), so that sensitive business information is immediately cleared from the active display.
22. As an operator navigating across the application, I want all route transitions and redirections to occur smoothly without visible flashes of unauthorized screens, so that the experience feels polished and secure.

## Implementation Decisions

- **Route Surface Classification**: Routes across the application are formally grouped into four discrete access tiers:
  - *Public Auth Routes*: Exclusively unauthenticated entry points (`/login`, `/register`).
  - *Store Onboarding Routes*: Setup workflows reserved for authenticated operators lacking a store entity (`/store-info`, `/create-store`, `/store/create`).
  - *Hard-Guarded Routes*: Sensitive operator and administrative areas (`/profile`, `/users`) strictly requiring an authenticated session.
  - *General Exploratory Routes*: Catalog and overview screens (`/home`, `/items`, `/categories`, etc.) accessible to both Guests and authenticated operators.
- **Centralized Declarative Router Guard**: All redirection rules are consolidated inside the top-level router configuration using a single declarative redirect handler, completely replacing imperative post-frame callbacks and widget-level listeners.
- **Reactive Stream Synchronization**: The router configuration is equipped with a reactive refresh listenable that merges emission streams from the authentication controller and store profile controller. Any state mutation (login, logout, store registration) immediately triggers a route re-evaluation without requiring page reloads.
- **URL-Preserved Return Destination**: Workflow continuation is standardized via the query parameter `returnRoute`. Guarded redirects append `?returnRoute=<encodedPath>`, and post-authentication resolution honors this parameter above default landing dashboards.
- **Canonical Role Destination Hierarchy**: Default post-login destinations (in the absence of a `returnRoute`) are resolved through a canonical mapping function that respects role precedence:
  1. `admin` $\to$ `/admin/dashboard`
  2. `store` or `retail` $\to$ `/store/dashboard`
  3. `delivery` $\to$ `/delivery/orders`
  4. Default $\to$ `/home`
- **Single-Store Invariant Enforcement**: Authenticated operators possessing an active store entity are strictly prevented from visiting store onboarding paths (`/store-info`, `/create-store`), redirecting to their role dashboard to safeguard the single-store architectural rule.

## Testing Decisions

- **Testing Philosophy**: Redirection tests must exclusively evaluate external user-observable behavior—specifically the final URL location and the rendered view type—rather than querying private controller variables or internal guard flags.
- **Testing Seam (Top-Level Router Integration Seam)**:
  - A single, top-level integration harness mounting the application router under a test app container.
  - The harness injects controllable authentication and store state controllers.
  - Navigation actions (`go`, deep links, URL updates) and state transitions (guest entry, successful login, store profile creation, logout) are executed against the harness to verify:
    - Guests accessing `/profile` or `/users` are redirected to `/login?returnRoute=...`.
    - Authenticated operators accessing `/login` or `/register` are redirected to their role dashboard or onboarding.
    - Operators with an existing store accessing `/store-info` are redirected to their dashboard.
    - Post-login navigation respects `returnRoute` over default role dashboards.
- **Prior Art**: Aligns with the architectural access testing specifications established in `docs/specs/0004-authentication-store-onboarding-and-guest-access.md` and the user state definitions in `GLOSSARY.md`.

## Out of Scope

- Role-based granular button disabling within individual pages (governed by component-level authorization).
- Password reset self-service workflows via email/SMS links.
- Multi-branch store switching under a single operator profile.
- Persistent guest carts or local drafts transitioning across distinct physical devices.

## Further Notes

- References [ADR 0003](../adr/0003-backend-auth-and-guest-tiering.md) on elimination of client-side demo shortcuts and standardization on backend authentication.
- References [ADR 0005](../adr/0005-centralized-reactive-router-redirection.md) on centralized declarative reactive router redirection.
- Conforms strictly to domain terminology defined in [GLOSSARY.md](../../GLOSSARY.md), specifically `Operator`, `Guest`, `Role`, `Access Level`, `Public Auth Route`, `Store Onboarding Route`, and `Guarded Route`.
