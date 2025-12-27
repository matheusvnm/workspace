# Jira Analysis & Planning Command

You are analyzing a Jira ticket for the HGE Django project and proposing implementation strategies.

## Task

Analyze a Jira ticket (Epic, Task, Bug, Technical Debt) and provide:
1. What is being asked and why
2. General explanation of relevant code (unless asked not to)
3. Two possible implementation strategies

## Reference Documentation

Refer to the full agent documentation at: `~/.claude/agents/hge-jira-analyze.md`

## Analysis Process

### 1. Fetch Jira Ticket

Get complete ticket information:
- Ticket number, title, description
- Acceptance criteria
- Linked issues (blocks, is blocked by, relates to)
- Subtasks
- Comments with additional context
- Priority and labels

### 2. Understand Requirements

Extract and clarify:
- **What** is being asked (primary requirement)
- **Why** it's needed (business context)
- **Success criteria** (acceptance criteria)
- **Dependencies** (linked issues, blockers)
- **Constraints** (Zope compatibility, performance, roles)

### 3. Identify Affected Code

Determine:
- **Primary module(s)** involved
- **Related modules** that may be affected
- **Specific files** to create or modify
- **Existing patterns** to follow
- **Similar features** in codebase for reference

### 4. Explain Current Implementation

**Include by default** unless user says:
- "without code explanation"
- "skip code details"
- "just the strategies"

Explain:
- Current architecture
- Relevant models and views
- Permission patterns
- Database relationships
- Similar existing features

### 5. Propose Two Strategies

Provide **TWO different approaches**, each with:

**Strategy A - Typically simpler/faster:**
- Overview and approach
- Implementation steps
- Files affected
- Pros and cons
- Complexity level
- Estimated effort
- Risks and mitigations
- Zope compatibility impact

**Strategy B - Typically more comprehensive:**
- Same structure as Strategy A
- Different architectural approach
- Different trade-offs

**Common strategy types:**
- Minimal vs. Comprehensive
- Admin-only vs. Full UI
- Quick MVP vs. Long-term solution
- Simple vs. Flexible
- Phase 1 vs. Complete

### 6. Comparison & Recommendation

- Comparison table of strategies
- Clear recommendation with reasoning
- Consider: timeline, user experience, maintainability, future needs

## Key Considerations

**HGE Project Specifics:**
- 23 modular architecture - which modules involved?
- Dual database (Django + Zope) - compatibility?
- Feature flags - needed?
- Role-based access - which roles affected?
- Existing patterns - what to follow?

**Zope Compatibility:**
- Does Zope need to read this data?
- Database router considerations
- Migration impact

**User Roles:**
- Office, Manager, Field, Sales, Subcontractor
- Division-level restrictions
- Permission patterns

## Instructions

1. **Ask for ticket number** if not provided
2. **Fetch ticket details** from Jira (or ask user to provide)
3. **Read linked issues and subtasks** - they're important!
4. **Explore codebase** - find relevant modules and files
5. **Understand context** - why this is needed
6. **Explain current code** - unless asked not to
7. **Propose TWO strategies** - with different trade-offs
8. **Compare and recommend** - help user decide
9. **Be specific** - actual file paths, concrete steps
10. **Be realistic** - accurate effort estimates

## Output Format

```markdown
# Jira Analysis: [TICKET-NUMBER]

**Ticket:** [Number] - [Title]
**Type:** [Type]
**Priority:** [Priority]

**Linked Issues:**
[List with relationships]

**Subtasks:**
[List if any]

---

## 1. What is Being Asked and Why

**Requirement:**
[Clear statement]

**Current State:**
[How it is now]

**Desired State:**
[How it should be]

**Business Value:**
[Why it matters]

**Acceptance Criteria:**
- [ ] [Criteria]

---

## 2. Code Explanation

[Include unless user says not to]

### Current Implementation
[Relevant code explanation]

### Relevant Architecture
[How it works now]

---

## 3. Implementation Strategies

### Strategy A: [Name]

**Overview:**
[Description]

**Implementation Steps:**
1. [Steps]

**Files to Create/Modify:**
[Lists]

**Pros:**
[Advantages]

**Cons:**
[Disadvantages]

**Complexity:** [Low/Medium/High]
**Estimated Effort:** [Time]
**Risks:** [List with mitigations]
**Zope Compatibility:** [Impact]

---

### Strategy B: [Name]

[Same structure]

---

## Strategy Comparison

[Comparison table]

---

## Recommendation

[Recommendation with reasoning]
```

Begin Jira analysis now.
