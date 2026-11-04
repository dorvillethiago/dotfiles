param([switch]$Force)

$repo = Split-Path $PSScriptRoot
$links = @(
    # Windows Terminal settings
    @{ Link = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
       Target = "$repo\windows-terminal\settings.json" }
    # PowerShell 7 profile (MyDocuments follows OneDrive redirection, $PROFILE differs between 5.1 and 7)
    @{ Link = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "PowerShell\Microsoft.PowerShell_profile.ps1"
       Target = "$repo\powershell\profile.ps1" }
)

function Test-Linked([hashtable]$Entry) {
    $item = Get-Item $Entry.Link -Force -ErrorAction SilentlyContinue
    $item -and $item.LinkType -eq "SymbolicLink" -and $item.Target -eq $Entry.Target
}

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

# Creating symlinks needs admin or Developer Mode (Settings -> System -> For developers).
# With neither, run just this script elevated (one UAC prompt) so the rest of setup stays non-admin.
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$devMode = [Microsoft.Win32.Registry]::GetValue('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock', 'AllowDevelopmentWithoutDevLicense', 0) -eq 1
$pending = @($links | Where-Object { -not (Test-Linked $_) })

if ($pending -and -not $isAdmin -and -not $devMode) {
    Write-Host "Symlinks need admin (or Developer Mode) - asking for it in a separate window..."
    $relaunch = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"")
    if ($Force) { $relaunch += '-Force' }
    try {
        Start-Process (Get-Process -Id $PID).Path -Verb RunAs -ArgumentList $relaunch -Wait
    } catch {
        Write-Warning "Admin prompt declined - configs outside home aren't linked. Enable Developer Mode or run .\scripts\link.ps1 again."
        return
    }
    # The elevated window closes when done, so report the result here
    foreach ($entry in $links) {
        if (Test-Linked $entry) { Write-Host "Linked $($entry.Link)" }
        else { Write-Warning "Not linked: $($entry.Link)" }
    }
    return
}

foreach ($entry in $links) {
    New-Symlink -Link $entry.Link -Target $entry.Target
}
