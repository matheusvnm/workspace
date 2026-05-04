---
name: daily-reporter
description: Use when the user asks for a daily standup update, daily summary, activity report, or wants to know what they did recently on GitHub and Jira. Gathers activity from both sources and formats a copy-paste-ready standup message.
---

# Daily Reporter

## Overview

Gathers recent GitHub and Jira activity, then formats it into a conversational standup message with "Previous" and "Next" sections ready to paste into Slack or Teams.

## When to Use

- User asks for a "daily update", "standup summary", or "what did I do today/yesterday"
- User wants a summary of their GitHub or Jira activity
- User mentions daily chat, standup, or sync

## Workflow

### Step 1: Identify the user

```bash
git config user.name        # Display name for the message header
gh api user --jq '.login'   # GitHub username for API queries
```

### Step 2: Determine the time window

- Default: last working day (skip weekends -- if today is Monday, use Friday as cutoff)
- If the user specifies a range ("last week", "since Monday"), adjust accordingly
- Use ISO 8601 date format for API queries (e.g., `2026-05-03`)

### Step 3: Gather GitHub activity

Run these in parallel:

**PRs authored (recently updated):**
```bash
gh api search/issues --method GET \
  -f q='author:<username> type:pr sort:updated-desc' \
  -f per_page=15 \
  --jq '.items[] | select(.updated_at >= "<cutoff>") | "PR #\(.number) [\(.state)] \(.title) (\(.repository_url | split("/") | .[-2:] | join("/")))"'
```

**PRs reviewed or commented on (exclude self-authored):**
```bash
gh api search/issues --method GET \
  -f q='commenter:<username> type:pr sort:updated-desc' \
  -f per_page=15 \
  --jq '.items[] | select(.updated_at >= "<cutoff>") | "PR #\(.number) [\(.state)] \(.title) (\(.repository_url | split("/") | .[-2:] | join("/")))"'
```

**Recent events:**
```bash
gh api "users/<username>/events" --paginate \
  --jq '.[] | select(.created_at >= "<cutoff>") | "\(.type) \(.repo.name) \(.payload.action // "")"' \
  | head -50
```

For each relevant PR, enrich with:
```bash
gh pr view <number> --repo <owner/repo> \
  --json title,state,mergedAt,reviewDecision \
  --jq '{title, state, reviewDecision, mergedAt}'
```

### Step 4: Gather Jira activity

**REQUIRED:** Uses `acli jira` CLI. See the `acli-jira` skill for conventions (always use `--json`, parse with python/jq).

Run these in parallel:

**Tickets with recent status changes (completed work):**
```bash
acli jira workitem search \
  --jql "assignee = currentUser() AND status changed DURING (-1d, now()) ORDER BY updated DESC" \
  --fields "key,summary,status,priority" --limit 15 --json
```

**Tickets currently in progress (upcoming work):**
```bash
acli jira workitem search \
  --jql "assignee = currentUser() AND status != Done ORDER BY updated DESC" \
  --fields "key,summary,status,priority" --limit 15 --json
```

Parse JSON output to extract key, summary, and status:
```bash
python3 -c "
import sys, json
data = json.load(sys.stdin)
for i in data:
    print(f'{i[\"key\"]} [{i[\"fields\"][\"status\"][\"name\"]}] {i[\"fields\"][\"summary\"]}')
"
```

### Step 5: Categorize activity

**Previous (last working day):**
- Jira tickets moved to Done in the time window
- GitHub PRs authored and merged in the time window
- GitHub PR reviews given to teammates (PRs commented on that user did not author)

**Next (today / upcoming):**
- Jira tickets assigned to user with status "In Progress" or similar active states
- Any work the user explicitly mentions (e.g., specific ticket IDs)
- Follow-ups on open PR reviews

Cross-reference Jira ticket IDs found in GitHub PR titles with Jira data to avoid listing the same work twice.

### Step 6: Format the standup message

Use this exact format:

```
**<Display Name>**

Hey everyone! Here are my updates:

Previous:
- <completed item 1, use Jira ticket ID when available, e.g. (AUTH-1234)>
- <completed item 2>

Next:
- <current/planned item 1>
- <current/planned item 2>
```

**Formatting rules:**
- Bold the display name as header
- Conversational intro: "Hey everyone! Here are my updates:"
- Two sections: "Previous:" and "Next:" each followed by bullet points
- Use Jira ticket IDs when available from PR titles or Jira data (e.g., AUTH-2682)
- Do NOT include GitHub PR numbers (e.g., "#56") -- use ticket IDs or plain descriptions
- Keep bullet points concise -- one line each, no sub-bullets
- Lead "Previous" with merged/completed work, then reviews
- Lead "Next" with actively in-progress tickets, then planned work
- If no items for a section, write "- No updates" rather than omitting it

### Step 7: Present and iterate

Show the formatted message to the user. Ask if they want to adjust anything -- add tasks, remove items, change wording. Incorporate any manually mentioned work items the user provides.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Including GitHub PR numbers like "#56" | Use Jira ticket IDs from PR titles or Jira data |
| Listing same work from both GitHub and Jira | Cross-reference ticket IDs to deduplicate |
| Wrong time window on Mondays | Use Friday as the cutoff, not Saturday/Sunday |
| Missing reviewed PRs | Always check commenter search, not just author |
| Overly verbose bullets | Keep each bullet to one concise line |
| Skipping Jira data | Always query both GitHub AND Jira |
