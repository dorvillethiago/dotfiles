---
description: Turn a pasted task into a plan + implementation
argument-hint: <task content>
---

Here is a task from our board:

<task>
$ARGUMENTS
</task>

Follow the git rules in CLAUDE.md throughout.

## Workflow
1. Summarize the goal in 1-2 sentences and list the acceptance criteria (explicit and implicit).
2. Explore the codebase and identify the affected files/components.
3. List any questions or ambiguities. If any of them is blocking, stop and ask me before writing code.
4. Propose a short step-by-step plan and wait for my approval.
5. After approval: do the git setup from CLAUDE.md (update `development`, create a new branch), implement following the project's conventions (see the project's CLAUDE.md), and run lint/typecheck/tests.
6. Summarize what changed and the name of the branch you created. Don't commit or open a PR unless I ask.