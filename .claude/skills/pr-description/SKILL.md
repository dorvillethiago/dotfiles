---
name: pr-description
description: Format for pull request titles and descriptions, including a test plan for the reviewer. Use whenever writing, drafting, or opening a PR (e.g. before running `gh pr create`) or when asked for a PR description.
---

# PR description

## Format
Use exactly this structure, nothing more:

```markdown
## What this PR does
<2-4 lines explaining what changed and why, in terms of behavior>

## How to test
1. <step the reviewer performs>
2. <step>
   - Expected: <what should happen>
```

## Rules
- Base branch: `development`, unless I say otherwise.
- Keep it concise: explain only what the PR does. Don't list changes file by file, don't restate the whole task, and don't add extra sections.
- The test plan is for the reviewer: concrete, reproducible steps (route, action, input data) with the expected result. Include relevant edge cases and how to verify nothing else broke.
- Title: short and imperative, e.g. `Add OTP resend button to login`.
- No mention of Claude anywhere (no "Co-Authored-By", no "Generated with Claude Code").
- Before running `gh pr create`, show me the title and description and wait for my approval.

## How to build it
1. Run `git diff development...HEAD` and `git log development..HEAD --oneline` to see what the branch actually changes.
2. Write the description from the diff, not from memory of the conversation.