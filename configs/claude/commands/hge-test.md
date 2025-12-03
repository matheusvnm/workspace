# Test Generation Command

You are generating tests for the HGE Django project.

## Task

Generate comprehensive tests following HGE Django testing patterns and best practices.

## Reference Documentation

Refer to the full agent documentation at: `~/.claude/agents/hge-test-generation.md`

## Test Structure

Generate tests following this module structure:
```
module_name/tests/
├── conftest.py           # Pytest fixtures
├── factories.py          # Factory-boy factories
├── test_models.py        # Model tests
├── test_views.py         # View tests
├── test_forms.py         # Form tests
├── test_api_views.py     # API tests
└── test_*.py             # Feature-specific tests
```

## Required Patterns

1. **Factories** - Use factory-boy with SubFactory for relationships
2. **Fixtures** - Create reusable fixtures in conftest.py
3. **Markers** - Use `@pytest.mark.django_db` for database tests
4. **Coverage** - Comprehensive coverage of business logic

## Test Categories

Generate tests for:
- **Model Tests** - String representation, validation, relationships
- **View Tests** - Authentication, authorization, correct data display
- **Form Tests** - Valid/invalid data, custom validation
- **API Tests** - List, create, retrieve, update operations
- **Permissions** - Different user roles
- **Edge Cases** - Boundary conditions, error handling

## Instructions

1. Analyze the code to understand what needs testing
2. Create or update factories in `factories.py`
3. Create fixtures in `conftest.py` if needed
4. Write comprehensive test cases
5. Ensure tests cover edge cases and permissions
6. Verify tests follow project patterns

## Output Format

Provide tests in this format:

```markdown
## Test Implementation

**Module:** [module_name]
**Coverage:** [What's being tested]

### Factories (factories.py)
[Factory implementations]

### Fixtures (conftest.py)
[Fixture implementations]

### Tests (test_*.py)
[Test implementations]

### Coverage Summary
[What's covered and percentage if known]
```

Generate comprehensive tests now.
