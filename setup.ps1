param([switch]$SkipStart)

# Runs as you: Scoop refuses to install elevated, and daemons shouldn't run elevated either.
if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Run setup.ps1 from a normal (non-admin) PowerShell prompt."
}

$scripts = Join-Path $PSScriptRoot "scripts"

Write-Host "==> [1/5] Installing packages..." -ForegroundColor Cyan
& "$scripts\packages.ps1"

Write-Host "==> [2/5] Configuring system & apps..." -ForegroundColor Cyan
& "$scripts\system.ps1"

Write-Host "==> [3/5] Registering startup shortcuts..." -ForegroundColor Cyan
& "$scripts\shortcuts.ps1"

Write-Host "==> [4/5] Wiring configuration symlinks..." -ForegroundColor Cyan
& "$scripts\link.ps1"

if (-not $SkipStart) {
    Write-Host "==> [5/5] Starting tiling environment..." -ForegroundColor Cyan
    & "$scripts\start.ps1"
}

Write-Host "==> Setup complete!" -ForegroundColor Green
