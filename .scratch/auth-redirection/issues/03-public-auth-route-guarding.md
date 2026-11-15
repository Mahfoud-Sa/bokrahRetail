# 03: Public Auth Route Redirection Guarding

**What to build:** Declarative guards on `/login` and `/register`. Allows unhindered access to Guests and unauthenticated visitors, while automatically redirecting authenticated operators away to their role dashboard or pending onboarding.

**Blocked by:** 02: Canonical Role-Based Landing and Return Route Resolution

**Status:** ready-for-agent

- [x] Identify if current route is a Public Auth Route (`/login`, `/register`)
- [x] If operator is authenticated and store profile is missing, redirect to `/store-info`
- [x] If operator is authenticated and store profile is active, redirect to role destination or `returnRoute`
- [x] If visitor or guest, permit access to `/login` and `/register`
