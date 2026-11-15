# 02: Canonical Role-Based Landing and Return Route Resolution

**What to build:** Centralized destination resolution in `AppRoutes` that resolves post-login landing paths by prioritizing `returnRoute` query parameters followed by the role hierarchy (`admin` -> `/admin/dashboard`, `store`/`retail` -> `/store/dashboard`, `delivery` -> `/delivery/orders`, fallback -> `/home`).

**Blocked by:** 01: Reactive Router Refresh Stream Bridge

**Status:** ready-for-agent

- [x] Add `AppRoutes.resolveRoleDestination(List<String> roles, {String? returnRoute})` helper
- [x] Support query parameter `returnRoute` extraction from `GoRouterState`
- [x] Ensure empty/null `returnRoute` falls back strictly to role hierarchy
