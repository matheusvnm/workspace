# Migrate Callers, Then Delete Legacy APIs

**Principle:** When a new API is the right design, migrate every internal caller and delete the old API in the same wave. Don't ship dual paths.

## Why

Keeping both old and new APIs creates dual-path complexity, slows cleanup, and makes the codebase feel append-only. Migrating callers and deleting the legacy path preserves elegance and reinforces subtractive refactoring.

## Rule

- Inventory callers, migrate them, delete the old API.
- Treat temporary adapters as exceptional and time-boxed, not default architecture.
- Update tests to assert the new contract; delete tests that only protect old implementation details.
- Applies when no external users depend on backward compatibility and the project can absorb coordinated breaking changes.

See also [[principles/subtract-before-you-add]], [[principles/redesign-from-first-principles]]
