# Fix Root Causes

**Principle:** Trace every problem to its root cause and fix it there. Symptom fixes accumulate into permanent debt.

## Pattern

- **Reproduce first.** Without a reliable repro you can't verify the fix.
- **Ask "why" until you hit bedrock.** Test fails → mock is wrong → interface changed → schema doesn't match runtime. Fix the schema, not the mock.
- **Resist guards.** Adding a `None` check or `try/except` to silence an `AttributeError` is a symptom fix. Why is it `None`? Fix that.
- **Check the pattern, not just the instance.** If one file has the bug, grep for the pattern. Fix all instances or make it structurally impossible.
- **Instrument when stuck.** Add logging, read the actual error. Don't guess.

## Restart Bugs: Suspect State Before Code

Code doesn't change between runs; state does. When something "fails after restart," suspect stale persistent state first — config, caches, lock files, serialized state.

## Own Every File You Touch

Don't label issues "pre-existing" to skip them. If you touch a file, you own its quality — fix the lint errors, style violations, and bugs you find regardless of who introduced them.

See also [[principles/prove-it-works]], [[principles/encode-lessons-in-structure]]
