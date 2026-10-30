# dotfiles

<p>Windows dotfiles and scripts for a tiling window manager experience.</p>

<img width="1568" height="662" alt="image" src="https://github.com/user-attachments/assets/351ff0f5-78ea-4141-a7df-010eb23432bd" />

## Setup

Run this from an elevated PowerShell prompt — no cloning needed:

```powershell
irm https://raw.githubusercontent.com/dorvillethiago/dotfiles/main/bootstrap.ps1 | iex
```

This will:
1. Install git if missing
2. Bare-clone the repo into `$HOME\.dotfiles` (existing files are backed up to `$HOME\.dotfiles-backup`)
3. Check out all dotfiles directly into `$HOME`
4. Run `setup.ps1` to install packages and wire up symlinks

> **Note:** Symlinks (for Windows Terminal settings) require either an elevated prompt or [Developer Mode](ms-settings:developers) enabled (Settings → System → For developers). Running `bootstrap.ps1` elevated covers both.

## Updating

```powershell
.\update.ps1
```

Pulls the latest changes from `main` and re-runs `setup.ps1`, which installs any newly added packages and re-links configs.

The repo lives bare in `~\.dotfiles` with your home folder as its working tree, so plain `git` in `~` won't see it. Use `dotgit` (defined in the PowerShell profile) instead: `dotgit status`, `dotgit add <file>`, `dotgit commit`, `dotgit push`. New files also need a `!` line in `.gitignore`, which ignores everything else in home.

## What's tracked

| File | Purpose |
|---|---|
| `komorebi.json` | Komorebi config — 7 BSP workspaces per monitor (I–VII), 10px padding |
| `applications.json` | Per-app Komorebi rules |
| `.config/yasb/config.yaml` | YASB bar layout and widget config |
| `.config/yasb/styles.css` | YASB stylesheet |
| `.config/yasb/connection.cmd` | Online/offline check behind the bar's globe icon (pings 1.1.1.1) |
| `.config/whkdrc` | Hotkey bindings for Komorebi |
| `win.ahk` | AutoHotKey v2 script — remaps Win key to open the Powertoys Command Palette |
| `bootstrap.ps1` | One-shot setup for a fresh machine |
| `setup.ps1` | Install packages and create startup shortcuts (idempotent) |
| `link.ps1` | Creates symlinks for configs outside `$HOME`, backing up existing files to `.bak` |
| `update.ps1` | Pulls latest and re-runs setup |
| `.gitconfig` | Git user config |
| `windows-terminal/settings.json` | Windows Terminal profiles, Mica Glass color scheme and keybindings |
| `powershell/profile.ps1` | PowerShell 7 profile (runs fastfetch, starts Starship), linked to `$PROFILE` |
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
| `Win` (tap) | Open quick launcher (YASB) |
