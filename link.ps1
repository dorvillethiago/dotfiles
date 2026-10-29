param([switch]$Force)

# Requires an elevated prompt or Developer Mode enabled:
# Settings -> System -> For developers -> Developer Mode

function New-Symlink {
    param([string]$Link, [string]$Target)

    # Get-Item instead of Test-Path so broken symlinks are still found
    $item = Get-Item $Link -Force -ErrorAction SilentlyContinue
    if ($item) {
        if ($item.LinkType -eq "SymbolicLink" -and $item.Target -eq $Target) {
            Write-Host "$Link already linked - skipping."
            return
        }
        if ($Force -or $item.LinkType -eq "SymbolicLink") {
            Remove-Item $Link -Force
        } else {
            # Keep the app's own file instead of skipping the link
            Move-Item $Link "$Link.bak" -Force
            Write-Host "Backed up $Link to $Link.bak"
        }
    }

    # The app may not have created its config folder yet
    $parent = Split-Path $Link
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    New-Item -ItemType SymbolicLink -Path $Link -Target $Target | Out-Null
    Write-Host "Linked $Link -> $Target"
}

$repo = $PSScriptRoot

# Windows Terminal settings
$wtSettings = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
New-Symlink -Link $wtSettings -Target "$repo\windows-terminal\settings.json"

# PowerShell 7 profile (MyDocuments follows OneDrive redirection, $PROFILE differs between 5.1 and 7)
$pwshProfile = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "PowerShell\Microsoft.PowerShell_profile.ps1"
New-Symlink -Link $pwshProfile -Target "$repo\powershell\profile.ps1"
