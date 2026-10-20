# Global instructions

## Git rules (mandatory, all projects)
- Never run `git commit`, `git push`, `gh pr`, or any command that creates a commit, pushes to the remote, or opens a PR without explicitly asking for my permission first. State the exact command you're about to run and wait for my approval, every time, even if I've approved a similar one before.
- NEVER add Claude as a co-author. No "Co-Authored-By", "Generated with Claude Code", or any mention of Claude in commit messages, PR descriptions, comments, or code.
- When starting work on a new task, before writing any code:
  1. Run `git status`. If there are uncommitted changes, stop and let me know.
  2. `git checkout development && git pull origin development` (if the repo has no `development` branch, ask me which base branch to use).
  3. Create a new branch from it: `git checkout -b <type>/<short-task-slug>` (type: feat, fix, chore, or refactor).
- PRs target `development` by default. When writing a PR title or description, use the `pr-description` skill.