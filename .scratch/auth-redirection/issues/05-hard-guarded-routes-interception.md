# 05: Hard-Guarded Route Interception for Guests

**What to build:** Route-level interception on sensitive operator views (`/profile`, `/users`). Immediately redirects Guests to `/login?returnRoute=<path>` to preserve intended workflow, while allowing general catalog browsing in read-only Guest mode.

**Blocked by:** 02: Canonical Role-Based Landing and Return Route Resolution

**Status:** ready-for-agent

- [x] Identify Hard-Guarded Routes (`/profile`, `/users`)
- [x] If visitor or guest attempts access, redirect to `/login?returnRoute=<currentPath>`
- [x] If authenticated, permit access (with role check on `/users` where applicable)
