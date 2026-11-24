# Workflows

## The loop

```
idea ──► spec ──► tickets ──► implement ──► verify ──► PR
          │                      │
          └── ADR (if a decision is architectural)
```

### 1. Idea → spec

Non-trivial work gets a spec in `docs/specs/`, numbered sequentially (`0001-...` through `0007-...` exist). A spec states the problem, the chosen behavior, route/API changes, and acceptance criteria.

- New architectural decision (storage, auth model, navigation strategy, external service) → also write `docs/adr/NNNN-<slug>.md`. Follow the existing five.
- Use the glossary's terms. If a concept has no name yet, resolve the name first — that is `/domain-modeling` territory.
- Don't skip the spec because "it's small." Small changes with no spec are fine only when no contract changes.

### 2. Spec → tickets

Break the spec into issues on GitHub (`gh issue create`), each independently verifiable. Label them `ready-for-agent` once they are fully specified. Link back with `Spec: docs/specs/NNNN-....md`.

Triage vocabulary and tracker mechanics: `triage-labels.md`, `issue-tracker.md`.

`/triage` moves incoming issues through `needs-triage` → `needs-info` / `ready-for-agent` / `ready-for-human` / `wontfix`.

### 3. Implement

Use the smallest rule set that applies: `architecture.md` for placement, `conventions.md` for style, `testing.md` for verification.

Rules of engagement:

- One ticket per change set. If you discover adjacent breakage, file an issue — don't expand scope.
- If implementation reveals the spec is wrong, update the spec in the same PR and say so in the description.
- If you add a dependency, justify it in the PR and check it supports all targets (Windows first).

### 4. Verify

Required before you say "done":

```powershell
flutter analyze     # no new issues
flutter test        # all pass
```

And manually, for UI or navigation changes: launch with `flutter run -d windows`, exercise the affected tier (guest / authenticated without store / authenticated with store), and check Arabic RTL.

### 5. PR

- Branch off `main`: `feat/<slug>`, `fix/<slug>`, `docs/<slug>`.
- Commits: Conventional Commits, one logical change each.
- PR body: what changed, why, how you verified, spec/issue links, and any follow-ups. `/pr` helps draft it.
- Squash or rebase is fine; keep `main` history readable.
- `/code-review` compares the branch against `main` on two axes — standards and spec.

## When to stop and ask

Pause and surface the question instead of guessing when:

- A change requires editing `bokrah_design_system` (separate repo, shared consumers).
- A change requires a new dependency, code generation, or a database layer.
- A rule here conflicts with an ADR.
- You need to delete or restructure existing feature folders.
- The design system lacks a token or component the UI needs.

## Handoff

If a session ends mid-task, leave a note in the issue (or `docs/specs/` for spec work) covering: what is done, what is next, what was tried and rejected, and the exact command that currently fails. The next agent starts with no memory of this one.
