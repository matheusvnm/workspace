# Refactoring Command

You are refactoring code in the HGE Django project.

## Task

Improve code quality while maintaining functionality following systematic refactoring patterns.

## Reference Documentation

Refer to the full agent documentation at: `~/.claude/agents/hge-refactoring.md`

## Refactoring Principles

1. **Maintain Functionality** - Never break existing behavior
2. **Improve Readability** - Make code self-documenting
3. **Follow Patterns** - Stay consistent with project structure
4. **Test Coverage** - Ensure tests exist and pass
5. **Incremental Changes** - Small, focused improvements

## Common Refactoring Patterns

1. **Extract Method/Function** - Break down long methods
2. **Remove Duplication** - DRY principle
3. **Improve Query Efficiency** - Optimize database queries
4. **Simplify Conditionals** - Reduce complexity
5. **Replace Magic Numbers** - Use constants
6. **Add Type Hints** - Improve type safety
7. **Replace Nested Loops** - Use comprehensions or better queries
8. **Improve Error Handling** - Proper exception handling
9. **Refactor Class-Based Views** - Extract methods
10. **Refactor Model Methods** - Use properties, cleaner logic

## Code Smells to Address

- Long methods (>50 lines)
- Large classes (>500 lines)
- Duplicate code
- Magic numbers/strings
- Complex conditionals
- Poor naming
- Deep nesting (>3 levels)
- Missing type hints

## Refactoring Process

1. **Analyze** - Understand current code
2. **Plan** - Define clear goals
3. **Test Coverage** - Ensure tests exist
4. **Refactor Incrementally** - Small changes
5. **Run Tests** - After each change
6. **Verify** - No regressions

## Safety Rules

- **NEVER** mix refactoring with new features
- **ALWAYS** have test coverage first
- **COMMIT** frequently with working code
- **RUN** tests after each change
- **VERIFY** Zope compatibility if relevant

## Output Format

```markdown
## Refactoring Plan

**Goal:** [What you're improving]
**Files:** [Affected files]
**Risk:** [Low/Medium/High]

### Current Issues
[Code smells]

### Proposed Changes
[What will change]

### Step-by-Step

#### Step 1: [Description]
**Before:**
[Current code]

**After:**
[Refactored code]

### Verification
[How to verify no regressions]

### Benefits
[Improvements achieved]
```

Begin refactoring now.
