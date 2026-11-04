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

# 3. Configure PowerToys: remove duplicate startup shortcut, enable native autorun, skip OOBE
$ptLnk = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\powertoys.lnk"
if (Test-Path $ptLnk) {
    Remove-Item $ptLnk -Force -ErrorAction SilentlyContinue
    Write-Host "Removed duplicate powertoys startup shortcut (managed via Task Scheduler)."
}

$ptConfigDir = "$env:LOCALAPPDATA\Microsoft\PowerToys"
if (-not (Test-Path $ptConfigDir)) {
    New-Item -ItemType Directory -Path $ptConfigDir -Force | Out-Null
}

$oobeFile = Join-Path $ptConfigDir "oobe_settings.json"
if (-not (Test-Path $oobeFile)) {
    Set-Content -Path $oobeFile -Value '{"openedAtFirstLaunch":true}' -Encoding utf8
}

$settingsFile = Join-Path $ptConfigDir "settings.json"
if (Test-Path $settingsFile) {
    try {
        $cfg = Get-Content $settingsFile -Raw | ConvertFrom-Json
        if (-not $cfg.startup) {
            $cfg.startup = $true
            $cfg | ConvertTo-Json -Depth 10 | Set-Content $settingsFile -Encoding utf8
        }
    } catch {}
} else {
    Set-Content -Path $settingsFile -Value '{"startup":true}' -Encoding utf8
}
