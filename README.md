# dotfiles

Windows tiling desktop setup using [Komorebi](https://github.com/LGUG2Z/komorebi), [YASB](https://github.com/amnweb/yasb), and [whkd](https://github.com/LGUG2Z/whkd).
![Uploading {0107E4F7-ED8B-4EB4-B4A1-E821678F97B6}.png…]()

## Setup

Run the setup script from an elevated PowerShell prompt:

```powershell
.\setup.ps1
```

This installs Scoop, then installs `komorebi`, `whkd`, `yasb`, `autohotkey`, and `powertoys` via Scoop. It also registers `win.ahk` as a startup entry.

## What's tracked

| File | Purpose |
|---|---|
| `komorebi.json` | Komorebi config — 7 workspaces, Ashes/Base16 theme, 10px padding |
| `applications.json` | Per-app Komorebi rules |
| `.config/yasb/config.yaml` | YASB bar layout and widget config |
| `.config/yasb/styles.css` | YASB stylesheet |
| `.config/whkdrc` | Hotkey bindings for Komorebi |
| `win.ahk` | AutoHotKey v2 script — remaps Win key to open the Powertoys Command Palette |
| `setup.ps1` | Bootstrap script |

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
| `Alt + q` | Close window |
| `Alt + m` | Minimize window |
| `Alt + p` | Pause Komorebi |
| `Alt + Shift + r` | Retile |
| `Alt + o` | Reload whkd config |
| `Alt + Shift + o` | Reload Komorebi config |
| `Win` (tap) | Open quick launcher (YASB) |
