$scripts = $PSScriptRoot
. "$scripts\utils.ps1"

$repoRoot = Split-Path $PSScriptRoot

# 1. Hotkeys script shortcut
Set-StartupShortcut -Name "win-hotkeys" `
                    -TargetPath (Join-Path $repoRoot "win.ahk") `
                    -WorkingDirectory $repoRoot

# 2. Komorebi & YASB shortcuts
# Prefer komorebic-no-console to avoid flashing a terminal on startup
$komorebiExe = if (Get-Command komorebic-no-console -ErrorAction SilentlyContinue) { "komorebic-no-console" } else { "komorebic" }

$entries = @(
    @{ Name = "komorebi"; Exe = $komorebiExe; Args = "start --whkd" },
    @{ Name = "yasb";     Exe = "yasb";      Args = "" }
)

foreach ($entry in $entries) {
    $exePath = (Get-Command $entry.Exe -ErrorAction SilentlyContinue).Source
    if ($exePath) {
        Set-StartupShortcut -Name $entry.Name -TargetPath $exePath -Arguments $entry.Args
    } else {
        Write-Warning "$($entry.Exe) not found in PATH - skipping startup shortcut."
    }
}
