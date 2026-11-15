# 01: Reactive Router Refresh Stream Bridge

**What to build:** A unified reactive `Listenable` bridge that observes `AuthCubit` and `StoreCubit` state streams and signals `GoRouter` to re-evaluate routes whenever authentication status or store state changes.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [x] Combine `AuthCubit.stream` and `StoreCubit.stream` into a single `ChangeNotifier` / `Listenable`
- [x] Connect the listenable to `GoRouter(refreshListenable: ...)`
- [x] Ensure disposal of stream subscriptions when the router is disposed
