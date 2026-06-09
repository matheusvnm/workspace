# Guard the Context Window

**Principle:** The context window is finite and non-renewable within a session. Every token that enters should earn its place.

## Pattern

- **Isolate large payloads.** Route DOM dumps, screenshots, and verbose tool outputs to subagents. The main context gets summaries.
- **Don't read what you won't use.** Read selectively based on relevance, not exhaustively.
- **Keep frequently-used content inline.** Skill templates used on every invocation belong in `SKILL.md`, not in `references/`. Split to references only when content is genuinely conditional.
- **Cap phase scope.** See [[principles/cost-aware-delegation]] for sizing.

See also [[principles/cost-aware-delegation]]
