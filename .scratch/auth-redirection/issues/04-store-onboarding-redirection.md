# 04: Store Onboarding Redirection & Single-Store Invariant

**What to build:** Access control on `/store-info` and `/create-store`. Redirects unauthenticated visitors to `/login?returnRoute=...`, permits authenticated operators lacking a store to configure their profile, and automatically redirects operators who already have a store entity away to their dashboard.

**Blocked by:** 02: Canonical Role-Based Landing and Return Route Resolution

**Status:** ready-for-agent

- [x] Identify if current route is a Store Onboarding Route (`/store-info`, `/create-store`, `/store/create`)
- [x] If visitor or guest, redirect to `/login?returnRoute=<currentPath>`
- [x] If operator is authenticated and has NO store, allow access to complete onboarding
- [x] If operator is authenticated and ALREADY has a store, redirect to their role dashboard
