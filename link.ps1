#Requires -RunAsAdministrator
# Alternatively, enable Developer Mode in Windows Settings > System > For developers,
# which lets non-admin users create symlinks.

param([switch]$Force)

function New-Symlink {
    param([string]$Link, [string]$Target)

    if (Test-Path $Link) {
        $item = Get-Item $Link -Force
        if ($item.LinkType -eq "SymbolicLink" -and $item.Target -eq $Target) {
            Write-Host "$Link already linked — skipping."
            return
        }
        if ($Force) {
            Remove-Item $Link -Force
        } else {
            Write-Warning "$Link exists and is not a symlink. Run with -Force to replace it."
            return
        }
    }

    New-Item -ItemType SymbolicLink -Path $Link -Target $Target | Out-Null
    Write-Host "Linked $Link -> $Target"
}

$repo = $PSScriptRoot

# Windows Terminal settings
$wtSettings = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
New-Symlink -Link $wtSettings -Target "$repo\windows-terminal\settings.json"
