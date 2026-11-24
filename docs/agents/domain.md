# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

## Before exploring, read these

- **`GLOSSARY.md`** at the repo root. It defines the retail vocabulary and lists the terms to avoid (mostly leftovers from the restaurant origin of the codebase).
- **`docs/adr/`**: read ADRs that touch the area you're about to work in. Five exist: auto-update via GitHub Releases, RBAC with permissions, backend auth and guest tiering, purging the restaurant layer, and centralized reactive router redirection.
- **`docs/specs/`**: numbered specs for implemented features. Read the relevant spec before changing that feature.

If any of these files don't exist, **proceed silently**. Don't flag their absence; don't suggest creating them upfront. The `/domain-modeling` skill creates them lazily when terms or decisions actually get resolved.

## File structure

Single-context repo:

```
/
├── GLOSSARY.md
├── docs/adr/
│   ├── 0001-use-github-releases-for-updates.md
│   └── ...
├── docs/specs/
│   ├── 0001-application-auto-update.md
│   └── ...
└── lib/app/
```

There is no `GLOSSARY-MAP.md`; do not introduce per-context glossaries without a decision to go multi-context.

## Use the glossary's vocabulary

When your output names a domain concept (in an issue title, a refactor proposal, a hypothesis, a test name), use the term as defined in `GLOSSARY.md`. Don't drift to synonyms the glossary explicitly avoids.

Examples of the distinction that matters here:

- Write **Store**, not restaurant/kitchen/dining outlet.
- Write **Operator**, not waiter/chef/cashier when referring to any staff member.
- Write **Guest** for the unauthenticated read-only tier.
- Write **Retail Tax Receipt**, not kitchen order ticket.

If the concept you need isn't in the glossary yet, that's a signal: either you're inventing language the project doesn't use (reconsider) or there's a real gap (note it for `/domain-modeling`).

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly rather than silently overriding:

> _Contradicts ADR-0005 (centralized reactive router redirection), but worth reopening because…_
