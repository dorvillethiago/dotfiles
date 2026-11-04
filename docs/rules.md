# Agent Rules & Development Protocol

All AI agents working within this repository must adhere to the following strict operational rules.

---

## 1. Mandatory Git Rules

### Explicit Approval for All Git Mutations
* **NEVER** run `git commit`, `git push`, `gh pr`, or any command that creates a commit, pushes to a remote, or creates a pull request without **explicit user permission**.
* **You must state the exact command** you are about to execute and wait for the user to approve it every single time.
* Example confirmation request:
  ```
  Ready to commit and push. Please confirm if I should run:
  git --git-dir=$HOME/.dwc-shell --work-tree=$HOME commit -m "feat: description"
  git --git-dir=$HOME/.dwc-shell --work-tree=$HOME push origin main
  ```

### No AI Attribution
* **NEVER** add Claude, Antigravity, or AI attribution in commit messages, PR descriptions, comments, or documentation.
* Do not include `Co-Authored-By`, `Generated with Claude Code`, or similar attribution lines.

---

## 2. Working in the Bare Repository Environment

### Git Command Invocation
Because this repository is checked out into `$HOME` from a bare clone at `$HOME\.dwc-shell`:
* Always use:
  ```pwsh
  git --git-dir=$HOME/.dwc-shell --work-tree=$HOME <command>
  ```
* Do not attempt to run standard `git <command>` directly inside `$HOME` unless using the `dwc git <command>` alias in interactive PowerShell.

### Whitelist `.gitignore`
* Root `.gitignore` uses `/*` to ignore everything in `$HOME`.
* When adding a new file or directory to track, you **must** add a whitelist entry `!/<path>` to `.gitignore`.
* If a new file is created but does not show in `git status`, check `.gitignore`.

---

## 3. PowerShell & Shell Safety

1. **Non-Admin Requirement**:
   Always run scripts from a normal, non-elevated user prompt. Scoop and tiling daemons must not run elevated.
2. **CRLF vs LF Line Endings**:
   PowerShell scripts on Windows typically use CRLF line endings. When using file editing tools, match exact line endings or make single-line substitutions to prevent target mismatch errors.
3. **Escaping in PowerShell Commands**:
   When invoking commands via PowerShell `-Command`, avoid ambiguous escaping with double quotes and environmental variables. Prefer single-quoted script blocks or `Join-Path`.
4. **Idempotency**:
   Every script (`setup.ps1`, `scripts/*.ps1`) must be safe to run multiple times without causing duplicate entries, redundant processes, or side effects.
