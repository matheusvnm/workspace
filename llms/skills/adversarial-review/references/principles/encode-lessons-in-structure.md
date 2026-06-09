# Encode Lessons in Structure

**Principle:** Encode recurring fixes in mechanisms (lint rules, tests, types, automation) — not in textual instructions. Every error and correction is a learning signal: capture it, route it, close the loop.

## Why

Textual instructions ("don't use bare excepts", "always run `ruff`") get ignored. Structural mechanisms enforce the rule without cooperation.

## Pattern

When you catch yourself writing the same instruction a second time:

1. Ask: can this be a lint rule, a type, a test, or a pre-commit hook?
2. If yes, encode it. Delete the instruction.
3. If no (genuinely judgment-based), make the instruction prominent and pair it with a concrete failure example.

**Corollary — don't paper over symptoms.** If a structural fix exists, only use the structural fix. The instruction *is* the symptom.

## Anti-Patterns

- **Acknowledging without recording.** "I'll keep that in mind" doesn't persist across sessions.
- **Recording without encoding.** A note saying "we should add a lint rule" without ever adding the rule.
- **Fixing without generalizing.** Patching one instance while the recurring pattern stays intact.

See also [[principles/never-block-on-the-human]]
