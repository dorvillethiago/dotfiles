# Daemons & Background Processes Reference

This document provides operational details for each daemon running within **DWC Shell**.

---

## Daemon Matrix

| Daemon | Package & Locked Version | Process Name(s) | Autostart Method | Config Location |
|---|---|---|---|---|
| **Komorebi** | `komorebi@0.1.41` | `komorebi.exe` | `shell:startup\komorebi.lnk` | `komorebi.json`, `applications.json` |
| **WHKD** | `whkd@0.2.10` | `whkd.exe` | Launched by `komorebi --whkd` | `.config/whkdrc` |
| **YASB** | `yasb@2.0.7` | `yasb.exe` | `shell:startup\yasb.lnk` | `.config/yasb/config.yaml`, `styles.css` |
| **PowerToys** | `powertoys@0.102.3001.0` | `PowerToys.exe`, `Microsoft.CmdPal.UI.exe` | Windows Task Scheduler (`settings.json` `"startup": true`) | `%LOCALAPPDATA%\Microsoft\PowerToys\settings.json` |
| **AutoHotkey** | `autohotkey` | `AutoHotkey64.exe` | `shell:startup\win-hotkeys.lnk` | `win.ahk` |

---

## 1. Komorebi & WHKD

### Version Pinning
Both tools are pinned to tested versions in `scripts/packages.ps1`:
* Komorebi: `0.1.41`
* WHKD: `0.2.10`
* Scoop holds both (`scoop hold komorebi`, `scoop hold whkd`).

### Process Management
* Komorebi is started using `komorebic-no-console start --whkd` (or `komorebic start --whkd`).
* This flags Komorebi to supervise WHKD alongside itself.
* To stop:
  ```pwsh
  komorebic stop --whkd
  ```
* To reload config after modifying `komorebi.json` or `applications.json`:
  ```pwsh
  komorebic reload-configuration
  # Hotkey shortcut: Alt + Shift + o
  ```
* To reload WHKD hotkeys after modifying `.config/whkdrc`:
  ```pwsh
  # Hotkey shortcut: Alt + o
  ```

---

## 2. PowerToys (Command Palette / CmdPal)

### Strict Configuration Rules
To maintain minimal resource consumption and prevent popup disruptions:
1. **Version Pinning**: Installed as `powertoys@0.102.3001.0` and held with `scoop hold powertoys`.
2. **OOBE Welcome Screen Suppression**:
   - `%LOCALAPPDATA%\Microsoft\PowerToys\oobe_settings.json` must contain `{"openedAtFirstLaunch":true}`.
   - `%LOCALAPPDATA%\Microsoft\PowerToys\last_version_run.json` must contain `{"last_version":"v0.102.3001"}`.
   - `"show_whats_new_after_updates": false` in `settings.json`.
3. **Module Masking**:
   - In `%LOCALAPPDATA%\Microsoft\PowerToys\settings.json`, `"enabled"` contains only `"CmdPal": true`.
   - All other 36+ modules (Awake, FancyZones, ColorPicker, TextExtractor, PowerToys Run, AlwaysOnTop, etc.) are set to `false`.
4. **Startup**:
   - `"startup": true` in `settings.json` configures Windows Task Scheduler.
   - Duplicate shortcuts in `shell:startup\powertoys.lnk` are actively pruned by `scripts/system.ps1`.

### Path Resolution
`scripts/utils.ps1` defines `Get-PowerToysPath`. It performs pure native filesystem checks on potential Scoop, Program Files, and LocalAppData installation paths with zero sub-process overhead. It must **never** invoke `scoop prefix powertoys` (which outputs error text to the console when uninstalled).

---

## 3. YASB (Yet Another Status Bar)

### Version Pinning
* Pinned to `yasb@2.0.7` and held with `scoop hold yasb`.

### Theme Switching Mechanism
YASB watches `.config/yasb/theme.css` on disk and automatically hot-reloads its UI when the file changes.
* Available theme stylesheets: `.config/yasb/themes/` (`glass.css`, `amoled.css`, `opaque.css`).
* `.config/yasb/theme.css` is intentionally **untracked** in Git so switching themes locally does not make the repository dirty.
* To switch themes:
  ```pwsh
  # Using the script
  .config/yasb/set-theme.ps1 amoled
  # Or through the TUI panel
  dwc -> Option 4: YASB Themes
  ```

---

## 4. AutoHotkey (`win.ahk`)

### Functions
1. **Windows Key Redirection**:
   Catches `~LWin::` release, suppresses Windows Start menu, and sends `#!{Space}` (`Win + Alt + Space`) to trigger PowerToys Command Palette.
2. **FL Studio Retile Quirk**:
   FL Studio window drag routines do not fire standard Win32 size/move completion events. `win.ahk` registers a global left-click listener: if the clicked window is of class `TFruityLoopsMainForm` and its coordinates changed on mouse release, it invokes `komorebic retile` hidden in the background.
