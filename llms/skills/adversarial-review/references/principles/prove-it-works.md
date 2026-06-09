# Prove It Works

**Principle:** Verify every output by checking the real thing directly — not proxies, self-reports, or "it compiles."

## Why

Indirect verification (file mtimes, log output, agent self-reports, "tests passed without me reading them") feels cheaper than direct observation, but acting on a wrong inference costs far more than checking the source.

## Pattern

After completing any task, ask: **"How do I prove this actually works?"**

- **Check the real outcome directly** (HTTP response, DB row, file contents). Not derived signals.
- **Read the actual value**, not a cached or summarized representation.
- **When verification fails, suspect the observation method first** — before suspecting the system.
- **Run the full path end-to-end**, not just the unit. For integrations (HTTP, queues, IPC) test the whole chain.
- **Test error paths**: bad input, missing files, timeouts.
- **If you can run it, run it.** Prefer automated verification over manual inspection.

## Trust Artifacts, Not Self-Reports

When verifying delegated work, inspect the actual output (`git diff --stat`, file contents, runtime behavior) — never the delegate's summary. Agents report what they intended, not always what happened. Scope violations and silent failures are invisible in self-reports but obvious in artifacts.

See also [[principles/fix-root-causes]]
