# Make Operations Idempotent

**Principle:** Design state-mutating operations to converge to the correct state regardless of how many times they run or where they start from. Always answer: "What if this runs twice? What if the previous run crashed halfway?"

## Why

Background jobs, CLI commands, webhooks, and migrations run in environments where crashes, restarts, and retries are normal. If an operation leaves partial state that changes the next outcome, every restart becomes a debugging session.

## Pattern

- **Convergent operations:** `CREATE TABLE IF NOT EXISTS`, `INSERT … ON CONFLICT DO NOTHING`, `git fetch` (vs. `git pull`).
- **Idempotency keys:** Webhook and async-task handlers accept a request/message ID and skip work that's already done.
- **Self-healing locks:** Check stale holders (PID liveness, expiry timestamp) and reclaim instead of deadlocking.
- **Transactional state changes:** "Process record + mark processed" go in one DB transaction. No partial-completion state to recover from.
- **Migrations:** Each step is safe to re-run, or the runner tracks completion atomically (e.g., Alembic's `alembic_version`).

## The Test

Before shipping, ask:

1. What if this runs twice in a row?
2. What if the previous run crashed at every possible point?
3. Does re-execution converge to the same end state?

If any answer is "depends on what state was left behind," the operation needs a reconciliation step.

See also [[principles/serialize-shared-state-mutations]], [[principles/fix-root-causes]]
