# Subtract Before You Add

**Principle:** When evolving a system, remove complexity first, then build. Deletion creates a simpler substrate that makes subsequent additions cleaner, smaller, and less error-prone.

## Pattern

- **Sequence removal before construction.** In plans, schedule deletion phases before build phases. Each piece of dead code or unused abstraction removed makes the next step simpler.
- **Cut before you polish.** Trim the feature set ruthlessly before investing in quality. Half-finished features are worse than missing ones.
- **Design for observed usage, not speculative edge cases.** If the real workflow is single-process or low-concurrency, prefer simpler designs that fit that reality.
- **When a reference adds nothing novel, delete it** — don't leave a stub.

See also [[principles/foundational-thinking]], [[principles/redesign-from-first-principles]]
