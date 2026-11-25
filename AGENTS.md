# Bokrah Retail — agent entry point

Flutter desktop-first retail POS / inventory app. Windows is the primary target; Android, iOS, Linux, and macOS scaffolding exist. The product is Arabic-first, RTL, and bilingual (AR/EN).

This file is a thin entry point. Read the rule file relevant to your task before editing code.

## Doc map

| File | Read it when |
| --- | --- |
| [`docs/agents/rules/architecture.md`](docs/agents/rules/architecture.md) | Touching layers, DI, routing, auth, permissions, or adding a feature |
| [`docs/agents/rules/conventions.md`](docs/agents/rules/conventions.md) | Writing any Dart or UI code |
| [`docs/agents/rules/testing.md`](docs/agents/rules/testing.md) | Adding tests or verifying a change |
| [`docs/agents/rules/gotchas.md`](docs/agents/rules/gotchas.md) | **Always** — before your first command and before claiming done |
| [`docs/agents/rules/workflows.md`](docs/agents/rules/workflows.md) | Turning an idea into a spec, tickets, or a PR |
| [`docs/agents/domain.md`](docs/agents/domain.md) | Naming domain concepts, writing specs or ADRs |
| [`docs/agents/issue-tracker.md`](docs/agents/issue-tracker.md) | Creating, reading, or triaging issues |
| [`docs/agents/triage-labels.md`](docs/agents/triage-labels.md) | Applying triage labels |

`GLOSSARY.md` (repo root) and `docs/adr/` are the domain vocabulary and decision record. `docs/specs/` holds numbered feature specs. Use their terms; do not invent synonyms.

## Commands

Run from the repo root.

| Task | Command |
| --- | --- |
| Install deps | `flutter pub get` |
| Static analysis | `flutter analyze` |
| All tests | `flutter test` |
| One test file | `flutter test test/features/companies/company_card_test.dart` |
| Run (Windows) | `flutter run -d windows` |
| Run against real API | `flutter run -d windows --dart-define=USE_MOCK_AUTH=false` |
| Release build | `flutter build windows --release` |
| Format | `dart format lib test` |

Mock auth is **on by default**. You do not need a backend to run the app.

## Definition of done

A change is done when:

1. `flutter analyze` reports **no new** issues (baseline: 0 errors, 29 info/warning — see gotchas).
2. `flutter test` passes.
3. New shared widgets or domain logic have a test.
4. No new hardcoded user-facing strings — use l10n keys.

## Hard rules

- Do not edit `bokrah_design_system` from this repo. It is a sibling checkout; changes there affect every app that consumes it. Report the need instead.
- Do not add `build_runner` / code generation without an ADR. There is none today.
- Do not hand-edit one of the two skills trees (`.agents/skills`, `.claude/skills`); they are managed by `skills-lock.json`.
- Check `git status` before touching shared widgets or routes — there is often uncommitted work in flight.

## Agent skills

### Issue tracker

Issues live in this repo's GitHub Issues, managed with the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default vocabulary: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context repo: one `GLOSSARY.md` plus `docs/adr/` at the root. See `docs/agents/domain.md`.
