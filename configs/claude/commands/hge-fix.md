# Bug Fix Command

You are fixing bugs in the HGE Django project.

## Task

Systematically diagnose and fix bugs following a methodical debugging process.

## Reference Documentation

Refer to the full agent documentation at: `~/.claude/agents/hge-bug-fix.md`

## Bug Fix Methodology

### 1. Understand the Bug
- Read bug description and Jira ticket
- Identify expected vs actual behavior
- Review error logs and stack traces
- Check recent changes to related code

### 2. Reproduce Locally
- Create minimal test case that reproduces bug
- Test in local environment
- Document reproduction steps

### 3. Investigate Root Cause
- Use debugging tools (Django shell, ipdb, logging)
- Check common issue areas:
  - Database queries (N+1 problems)
  - Permissions/authorization
  - Form validation
  - Template rendering
  - API serialization
  - Async/Celery tasks
  - Zope integration

### 4. Develop Fix
- Implement minimal fix for root cause
- Don't over-engineer
- Handle edge cases
- Consider performance impact

### 5. Test Thoroughly
- Create test that reproduces bug (fails before fix)
- Verify test passes after fix
- Run all related tests
- Test with different user roles
- Check for regressions

### 6. Document
- Add comments explaining fix
- Reference Jira ticket
- Document in PR description

## Debugging Tools

```bash
# Django shell
just django-shell

# View logs
just logs

# Run specific tests
just test path/to/test.py
```

## Common Bug Patterns

- **N+1 Queries** - Missing select_related/prefetch_related
- **Permission Issues** - Missing role checks
- **Null Safety** - Not handling None values
- **Race Conditions** - Concurrent operations
- **Edge Cases** - Empty lists, zero division

## Output Format

```markdown
## Bug Fix Summary

**Bug:** [Description]
**Jira:** [JIRA-XXX]
**Severity:** [Critical/High/Medium/Low]

### Root Cause
[What caused the bug]

### Fix Implementation
[What was changed]

### Code
[Fix code]

### Testing
[Test that reproduces and verifies fix]

### Edge Cases
[Considered edge cases]
```

Begin bug fixing now.
