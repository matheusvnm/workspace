# Pull Request Description Command

You are generating a Pull Request description for the HGE Django project.

## Task

Create a comprehensive PR description following HGE Django standards.

## Reference Documentation

Refer to the full agent documentation at: `~/.claude/agents/hge-git-messages.md`

## PR Title Format

Same as commit message: `<type>(<scope>): <subject>`

Example: `feat(jobs): add job collection tracking`

## PR Description Template

```markdown
## Summary

[Brief description - 1-3 sentences]

## Changes

- [Specific change 1]
- [Specific change 2]
- [Specific change 3]

## Motivation

[Why is this change needed? What problem does it solve?]

## Technical Details

[Technical information for reviewers]

## Screenshots

[If applicable]

```

## Instructions

1. Analyze all changes in the branch
2. Review git log for commit history
3. Check git diff against base branch
4. Identify affected modules and functionality
5. Fill out PR template comprehensively
6. Be specific and thorough
7. Use the Jira issue to provide context

Generate PR description now.
