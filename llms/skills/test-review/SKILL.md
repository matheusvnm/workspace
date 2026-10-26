---
name: test-review
description: Use after you add or change tests, or when the user asks you to review tests. Examine each new or changed test one at a time. Give a strong reason to keep it, or recommend that the user removes it.
---

# Test Review

Use this skill to keep only the tests that protect behavior.

## Rules

Do not keep tests for:

- CSS and styles.
- Constants.
- Behavior that a different test already covers.
- Implementation details that can change while the behavior stays the same.

Keep tests for:

- Business logic: the positive case, the negative case and the edge cases.
- Helper functions and utility functions.

## Procedure

1. Find the base branch. Use `git merge-base HEAD origin/main`. If the project uses a different base branch, use that branch.
2. List the new and changed tests. Use `git diff --name-only <base>...HEAD` and the uncommitted changes from `git status --short`.
3. Make a numbered list of each test case (file and test name). Show the list to the user.
4. Examine one test at a time. For each test, write:
   - **Behavior**: the behavior that the test protects.
   - **Regression**: the defect that the test finds if the code breaks.
   - **Overlap**: a different test that covers the same behavior, or "none".
   - **Decision**: "Keep" with a strong reason, or "Remove" with the rule that applies.
5. Stop after each test. Ask the user to accept or change the decision. Do not go to the next test before the user answers.
6. After the last test, remove the tests that the user agreed to remove.
7. Run the test suite. Tell the user the result.

## Strong reasons

A strong reason names a real defect that the test finds. These are not strong reasons:

- "It increases coverage."
- "It is good practice."
- "It tests that the function exists."
