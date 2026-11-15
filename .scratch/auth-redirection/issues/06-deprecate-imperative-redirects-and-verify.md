# 06: Deprecate Imperative Page Redirects & Top-Level Seam Verification

**What to build:** Cleans up duplicate post-frame callbacks and listeners from `LoginPage` and `RegisterPage`, and mounts the top-level router integration test harness verifying all route classes and user state transitions end-to-end.

**Blocked by:** 03: Public Auth Route Redirection Guarding, 04: Store Onboarding Redirection & Single-Store Invariant, 05: Hard-Guarded Route Interception for Guests

**Status:** ready-for-agent

- [x] Remove duplicate post-frame callback and `BlocListener` redirects from `LoginPage`
- [x] Align `RegisterPage` with router redirection flow
- [x] Create integration test suite at `test/router_redirection_test.dart`
- [x] Verify test suite passes cleanly
