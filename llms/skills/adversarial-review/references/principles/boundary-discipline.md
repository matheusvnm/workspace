# Boundary Discipline

**Principle:** Validate, narrow types, and handle errors at system boundaries. Trust internal code. Business logic lives in pure functions; framework wiring is thin and mechanical.

## Why

Validation scattered through a codebase is noisy, redundant, and gives a false sense of safety. Concentrate it at boundaries — each input is validated exactly once and flows freely after. Logic tangled with framework wiring can't be tested without the framework.

## The Pattern

- **At boundaries** (HTTP requests, CLI args, config, external APIs, queues): validate with Pydantic / dataclasses / typed schemas. Raise on bad input.
- **Inside the system**: typed data flows freely. No re-validation, no `isinstance` defenses, no "just in case" `None` checks. Trust the types.
- **Domain exceptions** (`OrderNotFound`, `InsufficientFunds`) propagate freely — handlers translate them to HTTP responses. No bare `try/except Exception: pass` inside services.
- **Route handlers stay thin**: parse → call service → format response. Service functions are `(InputModel) -> OutputModel` with no `Request`/`Response`/template dependencies.

## The Test

Before adding a validation check, ask: **"Is this crossing a system boundary right now?"** If not, it's redundant — trust the types.

Before putting logic in a route handler, ORM hook, or template, ask: **"Can this be a pure function the handler just calls?"** If yes, extract it.

See also [[principles/foundational-thinking]]
