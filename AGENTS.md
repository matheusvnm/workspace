# Agent Rules for This Repository

This repository controls the setup of a macOS machine. Read `README.md` before you change it.

## Sources of truth

- `manifests/` declares tools, installers, skills, plugins and permissions.
- `llms/` holds the global rules, local skills, commands and agents.
- Do not edit files that the reconciler generates or links on the machine, for example `~/.config/opencode/opencode.json`.
- `llms/AGENTS.md` holds the global rules for all projects. This file holds the rules for this repository only.

## Procedures

- To add, remove or update an item, follow `README.md` section 6.
- To add a new kind, follow `README.md` section 7.
- After each change, do the checklist in `README.md` section 8.

## Safety

- Do not run `just setup`, `just apply` or `just prune` without `--dry-run` or `DRY_RUN=1`, unless the user tells you to.
- Use `just diff` and `just prune --dry-run` to show the changes to the user.
- Do not run tests against the real `$HOME`. Use `setup_workspace` from `tests/helpers.bash`.

## Code

- Use bash 3.2 syntax in `automation/`.
- Write a bats test for each change to reconciler logic.
- Run `just test`, `just lint` and `just validate` before you commit.
- Use Conventional Commits messages.
