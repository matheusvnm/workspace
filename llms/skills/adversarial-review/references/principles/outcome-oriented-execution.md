# Outcome-Oriented Execution

**Principle:** Optimize for the intended, verifiable end state — not for keeping every intermediate step smooth. Final verification is non-negotiable.

## Why

In large refactors and migrations, forcing every intermediate step to stay fully stable creates temporary compatibility code that becomes long-lived debt. Converge directly on the target architecture and prove correctness at explicit verification boundaries.

## Rules

- End-state integrity beats transitional stability.
- Intermediate breakage is acceptable when it's planned, scoped, and reversible.
- Declare upfront where temporary breakage is and isn't OK.
- Require full static and runtime verification at plan completion.

## Anti-Pattern

Preserving obsolete code paths only to keep every intermediate commit green when no long-term compatibility is needed.

See also [[principles/migrate-callers-then-delete-legacy-apis]], [[principles/prove-it-works]]
