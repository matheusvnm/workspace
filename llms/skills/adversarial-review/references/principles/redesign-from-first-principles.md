# Redesign From First Principles

**Principle:** When integrating a change, don't bolt it onto the existing design — redesign as if the change had been a foundational assumption from day one.

- Read all affected files; understand the current design holistically.
- Ask: "if we were writing this from scratch with this new requirement, what would we build?"
- Propagate the change through every reference (types, docs, examples, rationale) so nothing reads as a patch.
- Think holistically; deliver incrementally.

This preserves [[principles/foundational-thinking|option value]] when integrating changes into an existing design.
