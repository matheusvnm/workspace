# Git Commit Message Command

You are generating a Git commit message for the HGE Django project.

## Task

Create a clear, consistent commit message following HGE Django Git standards.

## Reference Documentation

Refer to the full agent documentation at: `~/.claude/agents/hge-git-messages.md`

## Commit Message Format

```
<type>(<scope>): <subject>

[optional body]

[optional footer]

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Commit Types

- **feat**: New feature
- **fix**: Bug fix
- **refactor**: Code refactoring (no functionality change)
- **test**: Adding or updating tests
- **docs**: Documentation changes
- **style**: Code style/formatting
- **perf**: Performance improvements
- **chore**: Maintenance tasks
- **build**: Build system changes
- **ci**: CI/CD changes
- **revert**: Reverting a commit

## Scope

Module or area: `jobs`, `users`, `prospects`, `api`, `forms`, `models`, `views`, `tests`, etc.

## Subject Rules

1. Imperative mood: "Add feature" not "Added" or "Adds"
2. No period at end
3. Max 72 characters
4. Lowercase after colon
5. Clear and specific

## Body Guidelines

- Explain **WHY** the change was made
- Describe **WHAT** changed (if not obvious)
- Note **breaking changes**
- Reference **Jira tickets**
- Wrap at 72 characters

## Instructions

1. Run `git status` and `git diff` to see changes
2. Identify affected modules
3. Determine commit type
4. Write subject line (imperative, <72 chars)
5. Add body if needed (explain WHY)
6. Reference Jira ticket if applicable
7. Add Claude attribution footer

## Output Format

```markdown
## Suggested Commit Message

\`\`\`
<type>(<scope>): <subject>

<body>

<footer>
\`\`\`

## Analysis

**Changes Detected:**
[List changes]

**Scope:** [module/area]
**Type:** [feat/fix/etc]

**Rationale:**
[Why this type and scope]
```

Generate commit message now.
