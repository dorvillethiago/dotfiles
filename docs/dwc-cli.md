# DWC CLI & Management Panel

The `dwc` command is the central interface for configuring, inspecting, and monitoring the **DWC Shell** environment.

---

## 1. CLI Usage & Routing

Defined in `powershell/profile.ps1`:

```pwsh
dwc              # Launches the interactive TUI management panel
dwc update       # Pulls latest Git changes and runs setup.ps1
dwc code         # Opens VS Code scoped to the bare Git repo (~/.dwc-shell)
dwc git <args>   # Passes arbitrary Git commands to the bare repo
```

### Git Proxy Routing Rules
* Running `dwc git status` is equivalent to:
  ```pwsh
  git --git-dir=$HOME/.dwc-shell --work-tree=$HOME status
  ```
* For safety, `dwc <anything>` does **not** automatically default to git. To run git commands, the `git` subcommand must be explicitly provided (e.g. `dwc git log`).

---

## 2. Interactive TUI Menu (`scripts/panel.ps1`)

When running `dwc` with no arguments, an interactive terminal UI opens with smooth arrow-key navigation, ANSI cursor controls, and direct number shortcuts:

```
  ┌─────────────────────────────────────────────────────────┐
  │   DWC Shell · Dorville Windows Custom Shell             │
  └─────────────────────────────────────────────────────────┘

  [1] Update
  [2] Health Report
  [3] Resource Usage
  [4] YASB Themes
  [5] Shell Status
  [6] Exit
```

### Screen 1: Update
Executes `scripts/update.ps1`, which pulls `origin/main` for the bare repository and executes `setup.ps1` to re-apply any updated package versions, symlinks, or settings.

### Screen 2: Health Report
Performs an audit of the entire environment:
1. **Daemons**: Checks if Komorebi, WHKD, YASB, PowerToys, and AutoHotkey are `Installed & Running`, `Installed (Stopped)`, or `Not installed`.
2. **Symlinks**: Checks reparse points for PowerShell profile and Windows Terminal settings.
3. **Startup Registration**: Verifies presence of `.lnk` shortcuts in `shell:startup` and checks Task Scheduler state for PowerToys. PowerToys only reports `Enabled` if the binary is verified on the filesystem.

### Screen 3: Live Resource Usage Monitor
Displays a non-blocking real-time animated table tracking CPU% and WorkingSet memory usage across all daemons:

* **Target Filters**:
  * Komorebi: `komorebi*`
  * WHKD: `whkd*`
  * YASB: `yasb*`
  * AutoHotkey: `AutoHotkey*`
  * PowerToys: `@('PowerToys*', 'Microsoft.CmdPal*')`
* **Real-time Loop**:
  * Uses non-blocking console input polling (`$Host.UI.RawUI.KeyAvailable`).
  * Measures differential `TotalProcessorTime` divided by `ProcessorCount` and elapsed time.
  * Measures process `WorkingSet64` (RAM in MB).
  * Uses ANSI `$esc[H` home cursor positioning to avoid screen flicker.
  * Pressing `q` or `Escape` exits cleanly back to the menu.

### Screen 4: YASB Themes
Interactive sub-menu displaying installed themes from `.config/yasb/themes/` (`glass.css`, `amoled.css`, `opaque.css`). Selecting a theme immediately updates `.config/yasb/theme.css` without requiring a bar restart.

### Screen 5: Shell Status
Displays current branch, uncommitted changes, and commit difference against `origin/main` using `git status` on the bare repo.
