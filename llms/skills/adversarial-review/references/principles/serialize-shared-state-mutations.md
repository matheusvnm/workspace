# Serialize Shared-State Mutations

**Principle:** When concurrent actors share mutable state, enforce serialization structurally — locks, sequential phases, exclusive ownership. Conventions and instructions are insufficient for concurrency safety.

## Why

Concurrent writes to shared state (files, rows, queues, in-process globals) produce intermittent races that are hard to reproduce and expensive to debug. Telling asyncio tasks, threads, processes, or agents to "take turns" doesn't work — they have no coordination beyond the instruction itself.

## Pattern

Before any parallel execution (asyncio gather, threads, multiprocessing, multiple replicas):

1. **Identify shared mutable state.** Files, DB rows multiple workers update, module-level state, external APIs.
2. **Serialize access.** Row-level locks (`SELECT … FOR UPDATE`), advisory locks, file locks (`fcntl.flock`), single-writer queues, sequential phases.
3. **Or eliminate the sharing.** Per-task working directories, per-request context, separate connections.

## Common Failure Modes

- Two workers pulling the same job without `SELECT … FOR UPDATE SKIP LOCKED` — the job runs twice.
- Module-level mutable state (`_cache: dict = {}`) shared across asyncio tasks or threads with no lock.
- "Check-then-act" (`if not exists: create`) without atomicity — both callers create.
- Webhook handler updates a row while a background job rewrites it — last-write-wins corruption.

See also [[principles/make-operations-idempotent]], [[principles/encode-lessons-in-structure]]
