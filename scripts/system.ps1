$scripts = $PSScriptRoot
. "$scripts\utils.ps1"

# 1. Register Propo Nerd Fonts through Windows Shell so they load at sign-in
$fontKey = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
if (-not (Get-ItemProperty $fontKey -Name 'JetBrainsMono NFP Regular (TrueType)' -ErrorAction SilentlyContinue)) {
    $fontDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
    $shellFonts = (New-Object -ComObject Shell.Application).Namespace(0x14)
    Get-ChildItem "$env:USERPROFILE\scoop\apps\JetBrainsMono-NF-Propo\current" -Filter '*NerdFontPropo-*.ttf' -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-Item "$fontDir\$($_.Name)" -Force -ErrorAction SilentlyContinue
        $shellFonts.CopyHere($_.FullName, 0x14)
    }
    Write-Host "JetBrainsMono NFP fonts registered with Windows."
} else {
    Write-Host "JetBrainsMono NFP fonts already registered - skipping."
}

# 2. Disable Windows artificial startup delay and idle-state waiting
$serializeKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize'
if (-not (Test-Path $serializeKey)) {
    New-Item -Path $serializeKey -Force | Out-Null
}
Set-ItemProperty -Path $serializeKey -Name 'StartupDelayInMSec' -Value 0 -Type DWord
Set-ItemProperty -Path $serializeKey -Name 'WaitForIdleState' -Value 0 -Type DWord
Write-Host "Windows startup delay optimization configured."

# 3. Configure PowerToys: remove duplicate startup shortcut, enable native autorun, skip OOBE, enable ONLY CmdPal
$ptLnk = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\powertoys.lnk"
if (Test-Path $ptLnk) {
    Remove-Item $ptLnk -Force -ErrorAction SilentlyContinue
    Write-Host "Removed duplicate powertoys startup shortcut (managed via Task Scheduler)."
}

$ptConfigDir = "$env:LOCALAPPDATA\Microsoft\PowerToys"
if (-not (Test-Path $ptConfigDir)) {
    New-Item -ItemType Directory -Path $ptConfigDir -Force | Out-Null
}

# 3a. Suppress OOBE / Welcome screen on first start and updates
$oobeFile = Join-Path $ptConfigDir "oobe_settings.json"
Set-Content -Path $oobeFile -Value '{"openedAtFirstLaunch":true}' -Encoding utf8

$lastVersionFile = Join-Path $ptConfigDir "last_version_run.json"
Set-Content -Path $lastVersionFile -Value '{"last_version":"v0.102.3001"}' -Encoding utf8

# 3b. Configure settings.json: ensure ONLY CmdPal is enabled, auto-start is true, update toasts disabled
$allKnownModules = @(
    "AdvancedPaste", "AltWindowCycle", "AlwaysOnTop", "AutoHideCursor", "Awake",
    "CmdNotFound", "CmdPal", "ColorPicker", "CropAndLock", "CursorWrap",
    "EnvironmentVariables", "FancyZones", "File Explorer", "File Explorer Preview",
    "File Locksmith", "FindMyMouse", "GrabAndMove", "Hosts", "Image Resizer",
    "Keyboard Manager", "LightSwitch", "Measure Tool", "MouseButtonLock",
    "MouseHighlighter", "MouseJump", "MousePointerCrosshairs", "MouseWithoutBorders",
    "NewPlus", "Peek", "PowerDisplay", "PowerRename", "PowerToys Run",
    "QuickAccent", "RegistryPreview", "Shortcut Guide", "TextExtractor",
    "Workspaces", "ZoomIt"
)

$settingsFile = Join-Path $ptConfigDir "settings.json"
$cfg = $null
if (Test-Path $settingsFile) {
    try {
        $cfg = Get-Content $settingsFile -Raw | ConvertFrom-Json
    } catch {}
}

if (-not $cfg) {
    $cfg = [PSCustomObject]@{
        startup                             = $true
        show_tray_icon                      = $true
        show_theme_adaptive_tray_icon       = $false
        is_elevated                         = $false
        run_elevated                        = $false
        show_new_updates_toast_notification = $false
        download_updates_automatically      = $false
        include_prerelease_updates          = $false
        show_whats_new_after_updates        = $false
        enable_experimentation              = $false
        dashboard_sort_order                = 0
        is_admin                            = $false
        enable_warnings_elevated_apps       = $true
        enable_quick_access                 = $true
        theme                               = "system"
        system_theme                        = "dark"
        powertoys_version                   = "v0.102.3001"
        enabled                             = [PSCustomObject]@{}
    }
}

$cfg.startup = $true
$cfg.show_whats_new_after_updates = $false
$cfg.show_new_updates_toast_notification = $false
$cfg.download_updates_automatically = $false
if (-not $cfg.powertoys_version) {
    $cfg.powertoys_version = "v0.102.3001"
}

if (-not $cfg.enabled) {
    $cfg | Add-Member -MemberType NoteProperty -Name 'enabled' -Value ([PSCustomObject]@{} )
}

# Set all existing enabled properties to false except CmdPal
foreach ($prop in $cfg.enabled.PSObject.Properties) {
    $prop.Value = ($prop.Name -eq 'CmdPal')
}

# Ensure all known modules are explicitly declared
foreach ($mod in $allKnownModules) {
    $val = ($mod -eq 'CmdPal')
    if ($cfg.enabled.PSObject.Properties[$mod]) {
        $cfg.enabled.$mod = $val
    } else {
        $cfg.enabled | Add-Member -MemberType NoteProperty -Name $mod -Value $val
    }
}

$cfg | ConvertTo-Json -Depth 10 | Set-Content $settingsFile -Encoding utf8
Write-Host "PowerToys configured: OOBE suppressed, startup enabled, ONLY Command Palette (CmdPal) enabled."
