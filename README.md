# DWC Shell

<p><b>Dorville Windows Custom Shell</b> — A keyboard-centric tiling desktop and environment provisioner for Windows.</p>

<img width="1568" height="662" alt="image" src="https://github.com/user-attachments/assets/351ff0f5-78ea-4141-a7df-010eb23432bd" />

## Setup

Run this from a normal (non-admin) PowerShell prompt — no cloning needed:

```powershell
irm https://raw.githubusercontent.com/dorvillethiago/dwc-shell/main/bootstrap.ps1 | iex
```

This will:
1. Allow local scripts for your account (`RemoteSigned`) if Windows still blocks them
2. Install git if missing
3. Bare-clone the repo into `$HOME\.dwc-shell` (existing files are backed up to `$HOME\.dwc-shell-backup`)
4. Check out all configurations directly into `$HOME`
5. Run `setup.ps1` to install Scoop and packages, apply system tweaks, and wire up symlinks

> **Note:** Don't run it as administrator: Scoop refuses to install elevated, and the tiling apps shouldn't run elevated. The only step that needs admin is creating the symlinks for Windows Terminal and the PowerShell profile, so `scripts/link.ps1` shows a single UAC prompt for that — unless [Developer Mode](ms-settings:developers) is on (Settings → System → For developers), which allows symlinks without admin.

## CLI Usage

The repo lives bare in `~\.dwc-shell` with your home folder as its working tree. Use the `dwc` command defined in your PowerShell profile:

```powershell
dwc              # Open the interactive TUI management panel
dwc update       # Pull latest changes, re-run setup, and reload Komorebi
dwc code         # Launch VS Code with git panel scoped to dwc-shell
dwc git <cmd>    # Run git commands on dwc-shell (e.g. dwc git status, dwc git diff, dwc git push)
```

*(Aliases `wdc`, `dotupdate`, `dotgit`, and `dotcode` are also supported for backwards compatibility).*

New files also need a `!` line in `.gitignore`, which ignores everything else in home.

## What's tracked

| File | Purpose |
|---|---|
| `komorebi.json` | Komorebi config — 7 BSP workspaces per monitor (I–VII), 10px padding |
| `applications.json` | Per-app Komorebi rules |
| `.config/yasb/config.yaml` | YASB bar layout and widget config |
| `.config/yasb/styles.css` | YASB stylesheet |
| `.config/yasb/themes/*.css` | Bar themes (Glass, Amoled, Opaque); the palette icon in the bar picks one |
| `.config/yasb/set-theme.ps1` | Copies the picked theme over `theme.css`, which YASB reloads by itself (untracked, so switching never shows in git) |
| `.config/yasb/connection.cmd` | Online/offline check behind the bar's globe icon (pings 1.1.1.1) |
| `.config/whkdrc` | Hotkey bindings for Komorebi |
| `win.ahk` | AutoHotKey v2 script — remaps Win key to open the Powertoys Command Palette |
| `bootstrap.ps1` | One-shot setup for a fresh machine |
| `setup.ps1` | Orchestrator pipeline: calls modular scripts to configure the machine |
| `scripts/*.ps1` | Modular scripts (packages, system tweaks, shortcuts, linking, daemons, updates) |
| `.gitconfig` | Git user config |
| `windows-terminal/settings.json` | Windows Terminal profiles, Mica Glass color scheme and keybindings |
| `powershell/profile.ps1` | PowerShell 7 profile (`dwc` CLI, Starship, Fastfetch), linked to `$PROFILE` |
| `.config/starship.toml` | Starship prompt config |
| `.config/fastfetch/config.jsonc` | fastfetch system info, shown when a terminal opens |
| `.claude/CLAUDE.md` | Global Claude Code instructions (git rules, PR format) |
| `.claude/settings.json` | Claude Code preferences (theme, permissions) |
| `.claude/commands/task.md` | `/task` slash command |
| `.claude/skills/pr-description/SKILL.md` | `pr-description` skill |

## Keybindings

All bindings use `Alt` as the modifier.

| Key | Action |
|---|---|
| `Alt + h/j/k/l` | Focus window left/down/up/right |
| `Alt + Shift + h/j/k/l` | Move window left/down/up/right |
| `Alt + 1-8` | Switch to workspace |
| `Alt + Shift + 1-8` | Move focused window to workspace |
| `Alt + t` | Toggle float |
| `Alt + Shift + f` | Toggle monocle |
| `Alt + Enter` | Open a new terminal window |
| `Alt + q` | Close window |
| `Alt + m` | Minimize window |
| `Alt + p` | Pause Komorebi |
| `Alt + Shift + r` | Retile |
| `Alt + o` | Reload whkd config |
| `Alt + Shift + o` | Reload Komorebi config |
| `Win` (tap) | Open command palette |
