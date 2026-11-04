# DWC Shell — Agent Handbook

Welcome to **DWC Shell** (Dorville Windows Custom Shell). This repository provisions and manages a cohesive, keyboard-centric tiling desktop environment on Windows 11.

This handbook is written for AI agents working on this codebase. Read this document and the referenced guides before writing code or running commands.

---

## 1. Core Operating Context

### Dotfiles Architecture (Bare Git Repo)
Unlike standard codebases located within a dedicated project directory:
* The repository git database is stored as a **bare repo** at `$HOME\.dwc-shell` (`C:\Users\bitte\.dwc-shell`).
* The **working tree** is the user's home directory: `$HOME` (`C:\Users\bitte`).
* Every raw Git invocation must specify `--git-dir` and `--work-tree`:
  ```pwsh
  git --git-dir=$HOME/.dwc-shell --work-tree=$HOME <command>
  ```
* In interactive PowerShell sessions, the custom helper `dwc git <command>` proxies directly to this bare repository.

### Whitelist `.gitignore`
Because `$HOME` contains thousands of untracked personal and system files (AppData, documents, downloads):
* The root `.gitignore` begins with `/*`, ignoring **everything** in the home directory by default.
* Every newly introduced file or directory must be explicitly whitelisted in `.gitignore` using the `!` prefix (e.g. `!/new-file.ps1`). If you create a file and `git status` does not see it, update `.gitignore`.

### Non-Admin Execution Rule
* All scripts (`setup.ps1`, `bootstrap.ps1`, `scripts/*.ps1`) and all daemons must be run from a **standard, non-elevated user shell**.
* Running as administrator causes Scoop package installations to fail and breaks window manager hooks across privilege boundaries.
* The only administrative action required is symlink creation in `scripts/link.ps1`, which self-elevates via UAC if Windows Developer Mode is not enabled.

---

## 2. Component Directory Map

| Path | Description |
|---|---|
| `setup.ps1` | Primary idempotent setup orchestrator (steps 1–5). |
| `bootstrap.ps1` | One-shot setup script for fresh machine installation over HTTPS. |
| `scripts/packages.ps1` | Scoop bucket registration, pinned package installation, and version holding. |
| `scripts/system.ps1` | Font registration, Windows startup delay registry tweaks, and declarative PowerToys configuration. |
| `scripts/shortcuts.ps1` | Startup folder shortcut management (`shell:startup`). |
| `scripts/link.ps1` | Symlinks PowerShell profile and Windows Terminal settings. |
| `scripts/start.ps1` | Starts all tiling daemons if not already running. |
| `scripts/update.ps1` | Pulls remote Git updates and re-executes `setup.ps1`. |
| `scripts/panel.ps1` | Interactive TUI control center for `dwc` (Health, Resources, Themes, Git status). |
| `scripts/utils.ps1` | Shared utility library (`Get-PowerToysPath`, `Update-Path`, `Set-StartupShortcut`). |
| `powershell/profile.ps1` | PowerShell 7 profile defining `dwc` CLI, Fastfetch banner, Starship prompt, and keybinds. |
| `komorebi.json` | Komorebi tiling window manager configuration. |
| `applications.json` | Window rules, floating exceptions, and quirks for Komorebi. |
| `.config/whkdrc` | Hotkey definitions for WHKD (Windows Hotkey Daemon). |
| `.config/yasb/` | YASB top bar configuration (`config.yaml`), CSS styles, and theme stylesheets (`themes/`). |
| `win.ahk` | AutoHotkey v2 script for Start menu suppression, CmdPal activation, and mouse release retiling. |
| `windows-terminal/` | Windows Terminal configuration (`settings.json`). |
| `docs/` | Agent architecture, subsystem deep-dives, and operational rules. |

---

## 3. Documentation Index

For detailed guides on specific subsystems, consult the following documents in `docs/`:

1. [Architecture Overview](architecture.md) — System layers, IPC, process lifecycle, and hotkey routing.
2. [Daemons & Processes](daemons.md) — Detailed guide on Komorebi, WHKD, YASB, PowerToys CmdPal, and AutoHotkey.
3. [DWC CLI & Management Panel](dwc-cli.md) — How the `dwc` command and interactive TUI panel work, including real-time resource monitoring.
4. [Agent Rules & Git Protocol](rules.md) — Strict rules on Git permissions, no AI attribution, and branching workflow.
