# Migration Assistant Command

You are assisting with migrations for the HGE Django project.

## Task

Create safe, reversible migrations following HGE Django patterns and dual-database considerations.

## Reference Documentation

Refer to the full agent documentation at: `~/.claude/agents/hge-migration-assistant.md`

## Key Considerations

1. **Dual Database** - Django ORM + Legacy Zope database
2. **Zope Compatibility** - Ensure Zope can still read data
3. **Reversibility** - All migrations must be reversible
4. **Performance** - Consider impact on large tables
5. **Safety** - Test migrations locally first

## Migration Types

- **Schema Migrations** - Model changes (fields, indexes, constraints)
- **Data Migrations** - Transforming existing data
- **Zope-to-Django** - Porting functionality from Zope

## Instructions

1. Understand the current model and relationships
2. Check if Zope uses this table (critical!)
3. Plan migration steps carefully
4. Create migration with descriptive name
5. Make migration reversible
6. Test forward and rollback locally
7. Document any breaking changes

## Safety Checklist

- [ ] Migration has descriptive name
- [ ] Includes comments explaining changes
- [ ] Reversible (has reverse operation)
- [ ] Tested locally on database copy
- [ ] Zope compatibility verified
- [ ] Performance impact considered
- [ ] Batch operations for large tables

## Commands

```bash
# Create migration
python manage.py makemigrations module_name --name describe_operation

# Test forward
python manage.py migrate module_name

# Test rollback
python manage.py migrate module_name XXXX

# Check migration SQL
python manage.py sqlmigrate module_name XXXX
```

## Output Format

```markdown
## Migration Plan

**Type:** [Schema / Data / Zope-to-Django]
**Module:** [module_name]
**Description:** [Brief description]

### Changes
[List of changes]

### Zope Compatibility
[Impact on Zope]

### Migration File
[Migration code]

### Testing Steps
[How to test]

### Rollback Plan
[How to reverse]
```

Begin migration assistance now.
