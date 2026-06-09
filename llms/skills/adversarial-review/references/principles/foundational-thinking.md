# Foundational Thinking

**Principle:** Structural decisions (data models, phase ordering, infrastructure) optimize for option value. Code-level decisions (helpers, abstractions, patterns) optimize for simplicity.

Over-engineering means premature decisions that **close doors** — speculative abstractions, feature flags for hypothetical needs, indirection layers "in case we swap X." Choosing the right foundational data structure **opens doors** — it preserves option value.

## Data Structures First

Get the data shapes right before writing logic. The right structure makes downstream code obvious; the wrong one fights you at every turn.

- Define core models early (Pydantic, dataclasses, TypedDict) and let them drive the architecture.
- Trace every access pattern through a proposed shape: reads, writes, lookups, iteration, serialization.
- A shape change late in the project is a rewrite; early it's a one-line diff.

At the code level:

- **DRY at the structural level** (types, models) — but three similar lines is better than a premature abstraction.
- **Explicit over clever** — cleverness obscures intent.
- **Well-tested**: behavior and edge cases, not line coverage. See [[principles/prove-it-works]].

## Scaffold First

If something benefits all future work, do it first. CI, linting (`ruff`), type-checking (`mypy`/`pyright`), test infra (`pytest`), shared models, project config — all scaffold.

Sequence commits the same way: infra before features, tests before fixes. Keep commits small, single-purpose, and easy to revert.

[[principles/subtract-before-you-add]] comes before scaffolding — remove dead weight first, then lay foundations.

Ask: "does this decision reduce my future options, or preserve them?"

See also [[principles/redesign-from-first-principles]]
