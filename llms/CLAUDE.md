# Global Agent Rules

These rules apply to all projects.

## 1. Communication

- Write all output in US English.
- Use ASD-STE100 Simplified Technical English.
- Write short sentences. Use the active voice. Give one instruction in each sentence.
- Load the `asd-ste100` skill before you write a document, a commit message or a pull request text.

## 2. Tools

Use these tools before you write a custom script.

| Tool | Use it to | Example |
|---|---|---|
| `rg` | Find text in files | `rg -n "createUser" src` |
| `fd` | Find files by name | `fd -e ts user` |
| `ast-grep` | Find and change code by syntax | `ast-grep -p 'console.log($A)' -l ts` |
| `jq` | Read and change JSON | `jq '.scripts' package.json` |
| `yq` | Read and change YAML | `yq '.spec' manifest.yaml` |
| `gh` | Read and change GitHub pull requests, issues and checks | `gh pr view --comments` |
| `twg` | Read Jira and Confluence data | Load the `twg` skill |
| `sentry` | Read Sentry issues and events | Load the `sentry-cli` skill |
| `just` | Run project recipes | `just --list` |
| `uv` | Run Python tools and tests | `uv run pytest` |
| `bun` | Run JavaScript tools and tests | `bun test` |
| `kubectl` | Read Kubernetes resources | `kubectl get pods -n <namespace>` |
| `aws` | Read AWS resources | `aws s3 ls` |

- Use `ast-grep` for a structural search and for a change to many files.
- Use `rg` for a plain text search.

## 3. Skills

Load a skill when its condition is true.

| Skill | Load it when |
|---|---|
| `asd-ste100` | You write documents, commit messages or pull request text. |
| `humanizer` | The user asks you to make text sound less like AI text. |
| `ast-grep` | You search or change code by its syntax. |
| `grill-me` | The user asks you to question a plan or a design. |
| `grilling` | Another skill tells you to load it. |
| `codebase-design` | You design modules, interfaces or the structure of a codebase. |
| `domain-modeling` | You name domain concepts or design a domain model. |
| `test-review` | You add or change tests. |
| `logging-best-practices` | You add or change logs in a production system. |
| `upskill` | The user asks you to update skills from this session. |
| `twg`, `twg-*` | You read Jira or Confluence data. |
| `sentry-cli` | You read Sentry data. |

## 4. Commands

| Command | Use |
|---|---|
| `/bruh` | Say the last message again in plain words. |
| `/plannotator-review` | Review the current changes in the Plannotator user interface. |
| `/plannotator-annotate` | Add notes to a file in the Plannotator user interface. |
| `/plannotator-last` | Open the last plan in the Plannotator user interface. |

## 5. Plans and specifications

- Write each plan to `~/.claude/plans/<project_name>/<YYYY-MM-DD-topic>.md`.
- Write each specification to `~/.claude/specs/<project_name>/<YYYY-MM-DD-topic>.md`.
- `<project_name>` is the name of the root folder of the git repository.
- Do not write plans or specifications in the project repository.
- Keep one active plan for each task.
- Remove a plan when you merge its work.

## 6. Code

### Names

- Use names that show the intent.
- Do not use abbreviations.
- Start a boolean name with `is`, `has`, `can` or `should`.
- Start a function name with a verb.
- Do not use general names, for example `data`, `info`, `manager`, `helper` or `utils`.

### Comments and references

- Remove comments before you push code.
- If code needs a comment, change the code to make it clear.
- Remove ticket identifiers, TRD identifiers, specification identifiers and plan references from code, comments, test names and file names.

### Simplicity

- Use the simplest solution that works.
- Remove code that is not used.
- Do not add an abstraction that has only one user.
- Do not add a feature that the task does not need.

## 7. Git

- Push with an explicit branch name, for example `git push origin feature/payment-retry`.
- Do not push to `main`, `master`, `develop` or `pre-release` without approval from the user.
- Do not force push without approval from the user.

## 8. Tests

### Do not test

- CSS and styles.
- Constants.

### Test

- Business logic. Test the positive case, the negative case and the edge cases.
- Helper functions and utility functions.

### Review

- After you add or change tests, load the `test-review` skill.
- Give a strong reason for each new test, or remove it.
