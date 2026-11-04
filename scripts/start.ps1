$scripts = $PSScriptRoot
. "$scripts\utils.ps1"

$repoRoot = Split-Path $PSScriptRoot

# 1. Initialize default bar theme if missing (defaults to Glass)
$barTheme = Join-Path $repoRoot ".config\yasb\theme.css"
if (-not (Test-Path $barTheme)) {
    Copy-Item (Join-Path $repoRoot ".config\yasb\themes\glass.css") $barTheme
    Write-Host "Bar theme set to Glass."
}

# 2. Start tiling environment daemons if not already running
$komorebiExe = if (Get-Command komorebic-no-console -ErrorAction SilentlyContinue) { "komorebic-no-console" } else { "komorebic" }
if (-not (Get-Process -Name "komorebi" -ErrorAction SilentlyContinue)) {
    Write-Host "Starting komorebi..."
    Start-Process $komorebiExe -ArgumentList "start --whkd" -NoNewWindow
}

if (-not (Get-Process -Name "yasb" -ErrorAction SilentlyContinue)) {
    $yasbCmd = Get-Command yasb -ErrorAction SilentlyContinue
    if ($yasbCmd) {
        Write-Host "Starting yasb..."
        Start-Process $yasbCmd.Source
    }
}

$ptExe = Get-PowerToysPath
if ($ptExe -and -not (Get-Process -Name "PowerToys" -ErrorAction SilentlyContinue)) {
    Write-Host "Starting PowerToys..."
    Start-Process $ptExe -WorkingDirectory (Split-Path $ptExe)
}

$ahk = Join-Path $repoRoot "win.ahk"
if ((Test-Path $ahk) -and -not (Get-Process -Name "AutoHotkey*" -ErrorAction SilentlyContinue)) {
    Write-Host "Starting AutoHotkey..."
    Start-Process $ahk
}
