# Code Review Command

You are performing a code review for the HGE Django project.

## Task

Conduct a comprehensive code review following the HGE Django standards and best practices.

## Reference Documentation

Refer to the full agent documentation at: `~/.claude/agents/hge-code-review.md`

## Key Review Areas

1. **Architecture & Patterns** - Module structure, base classes, breadcrumbs, feature flags, dual database
2. **Django Best Practices** - Models, queries, foreign keys, migrations
3. **Views & Forms** - CBVs, role-based access, forms, AJAX handling
4. **API Patterns** - ViewSets, serializers, JWT auth
5. **Testing** - Factory-boy, test coverage
6. **Code Quality** - Ruff/Black formatting, no unused code
7. **Security** - SQL injection, permissions, CSRF, validation
8. **Zope Compatibility** - Database compatibility, legacy integration
9. **Performance** - Query efficiency, caching, async operations
10. **Documentation** - Complex logic, API docs, migration notes

## Instructions

1. Read all changed files completely using the Read tool
2. Check if there's a linked Jira ticket
3. Review code against the comprehensive checklist
4. Check test coverage
5. Look for security vulnerabilities
6. Verify performance considerations
7. Provide structured feedback with specific file/line references

## Output Format

Provide review in this format:

```markdown
## Code Review Summary

**Files Reviewed:** [list]
**Overall Assessment:** [APPROVE / REQUEST CHANGES / COMMENT]

## Strengths
[What was done well]

## Issues Found

### Critical Issues
[Must be fixed]

### Suggestions
[Nice to have]

## Specific Feedback
### [filename]:[line]
[Detailed feedback]

## Test Coverage
[Assessment]

## Security Considerations
[Any concerns]

## Jira Ticket Review
[Does this solve the requirements?]
```

Begin the code review now.
