# Form Builder Command

You are building Django forms for the HGE Django project.

## Task

Create Django forms following HGE Django patterns with proper validation and custom widgets.

## Reference Documentation

Refer to the full agent documentation at: `~/.claude/agents/hge-form-builder.md`

## Form Patterns

1. **Basic ModelForm** - Simple CRUD forms
2. **Custom Widgets** - Dollar fields, date pickers, select fields
3. **Multi-Step Forms** - Wizard forms with SessionWizardView
4. **Dynamic Forms** - Fields based on user role or context
5. **FormSets** - Multiple related forms
6. **AJAX Forms** - With JSONFormResponseMixin

## Available Custom Widgets

From `hge/ui/forms/controls/`:
- `WholeNumberControlDollarField` - Dollar amounts
- `DatePickerField` - Date selection
- `TimePickerField` - Time selection
- `TextAreaField` - Text area with counter
- `SelectField` - Styled dropdown
- `FileUploadField` - File uploads

## Form Structure

```python
class ModelNameForm(forms.ModelForm):
    class Meta:
        model = ModelName
        fields = [...]
        hidden_fields = [...]

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # Customize fields, widgets

    def clean_fieldname(self):
        # Field-level validation

    def clean(self):
        # Cross-field validation
```

## Instructions

1. Understand the model and requirements
2. Choose appropriate form pattern
3. Add custom widgets where needed
4. Implement validation (field-level and cross-field)
5. Create corresponding view
6. Create template
7. Add tests

## Validation Patterns

- **Field-level**: `clean_fieldname()` methods
- **Cross-field**: `clean()` method
- **Model validation**: Call `full_clean()` on instance
- **Custom validators**: Separate validator functions

## Output Format

```markdown
## Form Implementation

**Form Name:** [FormName]
**Model:** [ModelName]
**Purpose:** [Description]

### Form Code
[Form class]

### View Code
[View class]

### Template Code
[Template]

### URL Configuration
[URLs]

### Tests
[Test cases]
```

Begin form creation now.
