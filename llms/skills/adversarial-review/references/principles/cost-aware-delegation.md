# Cost-Aware Delegation

**Principle:** Every delegation has a budget. Account for the overhead of delegating itself, and hard-cap scope so work doesn't expand to fill available resources.

## Why

Agent turns, CI minutes, and API dollars are finite. Without explicit budgets, work expands — agents spend turns rediscovering context, coordination eats the margin, and CI runs time out.

## Pattern

- **Front-load context.** A longer prompt costs one read; rediscovery costs many turns. Every withheld piece of analysis is a turn wasted.
- **Hard-cap scope per phase.** A few files, one function or type plus tests. Without caps, work expands.
- **Pick the cheapest mechanism.** Coordinated multi-agent setups are expensive — prefer a direct subagent unless coordination is genuinely needed.
- **Exit on time.** Commit passing work before the budget runs out, not after.

See also [[principles/guard-the-context-window]]
