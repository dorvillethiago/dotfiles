function Update-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User")
}

function Get-PowerToysPath {
    $candidates = @(
        "$env:USERPROFILE\scoop\apps\powertoys\current\PowerToys.exe",
        "$env:ProgramFiles\PowerToys\PowerToys.exe",
        "${env:ProgramFiles(x86)}\PowerToys\PowerToys.exe",
        "$env:LOCALAPPDATA\Programs\PowerToys\PowerToys.exe"
    )
    foreach ($path in $candidates) {
        if ($path -and (Test-Path $path)) { return $path }
    }
    $scoopPrefix = scoop prefix powertoys 2>$null
    if ($scoopPrefix) {
        $pt = Join-Path $scoopPrefix "PowerToys.exe"
        if (Test-Path $pt) { return $pt }
    }
    return $null
}

function New-StartupShortcut {
    param(
        [string]$Name,
        [string]$TargetPath,
        [string]$Arguments       = "",
        [string]$WorkingDirectory = ""
    )

    $startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    $lnk = "$startupFolder\$Name.lnk"
    $WshShell = New-Object -ComObject WScript.Shell

    if (Test-Path $lnk) {
        $existing = $WshShell.CreateShortcut($lnk)
        $sameTarget = $existing.TargetPath.TrimEnd('\') -eq $TargetPath.TrimEnd('\')
        $sameArgs = ($existing.Arguments -replace '\s+', ' ').Trim() -eq ($Arguments -replace '\s+', ' ').Trim()
        $sameWorkDir = $existing.WorkingDirectory.TrimEnd('\') -eq $WorkingDirectory.TrimEnd('\')

        if ($sameTarget -and $sameArgs -and ($sameWorkDir -or -not $WorkingDirectory)) {
            Write-Host "$Name shortcut already up to date - skipping."
            return
        }
    }

    $shortcut  = $WshShell.CreateShortcut($lnk)
    $shortcut.TargetPath = $TargetPath
    if ($Arguments)        { $shortcut.Arguments       = $Arguments }
    if ($WorkingDirectory) { $shortcut.WorkingDirectory = $WorkingDirectory }
    $shortcut.Save()
    Write-Host "$Name startup shortcut saved."
}

# Runs as you: Scoop refuses to install elevated, and the apps started at the end shouldn't be
# elevated either. link.ps1 asks for admin itself if symlinks need it.
if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Run setup.ps1 from a normal (non-admin) PowerShell prompt."
}

# 1. Install Scoop (official installer, per-user)
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
    Update-Path
} else {
    Write-Host "Scoop already installed - skipping."
}

# 2. Add extras and nerd-fonts buckets
if (-not (scoop bucket list | Select-String "extras")) {
    scoop bucket add extras
}
if (-not (scoop bucket list | Select-String "nerd-fonts")) {
    scoop bucket add nerd-fonts
}

# 3. Install packages
$packages = @(
    @{ Name = "komorebi@0.1.41"; Check = { Get-Command komorebic -ErrorAction SilentlyContinue } },
    @{ Name = "whkd@0.2.10";     Check = { Get-Command whkd -ErrorAction SilentlyContinue } },
    @{ Name = "yasb@2.0.7";       Check = { Get-Command yasb -ErrorAction SilentlyContinue } },
    @{ Name = "autohotkey";       Check = { Get-Command autohotkey -ErrorAction SilentlyContinue } },
    @{ Name = "powertoys";        Check = { (Get-PowerToysPath) -ne $null } },
    @{ Name = "pwsh";             Check = { Get-Command pwsh -ErrorAction SilentlyContinue } },
    @{ Name = "starship";         Check = { Get-Command starship -ErrorAction SilentlyContinue } },
    @{ Name = "fastfetch";        Check = { Get-Command fastfetch -ErrorAction SilentlyContinue } },
    @{ Name = "JetBrainsMono-NF"; Check = { (Test-Path "$env:LOCALAPPDATA\Microsoft\Windows\Fonts\JetBrainsMonoNerdFont-*.ttf") -or (Test-Path "$env:windir\Fonts\JetBrainsMonoNerdFont-*.ttf") } },
    @{ Name = "JetBrainsMono-NF-Propo"; Check = { (Test-Path "$env:LOCALAPPDATA\Microsoft\Windows\Fonts\JetBrainsMonoNerdFontPropo-*.ttf") -or (Test-Path "$env:windir\Fonts\JetBrainsMonoNerdFontPropo-*.ttf") } }
)
foreach ($pkg in $packages) {
    if (& $pkg.Check) {
        Write-Host "$($pkg.Name) already installed - skipping."
    } else {
        scoop install $pkg.Name
    }
}
Update-Path

# Hold tiling and bar packages so 'scoop update *' never breaks dotfile configs
@("komorebi", "whkd", "yasb") | ForEach-Object { scoop hold $_ 2>$null }

# Scoop registers fonts by writing the registry itself, and Windows doesn't load the Propo ones
# at sign-in (yasb then falls back and clips its icons). Reinstalling them through the Shell
# font installer, like right-click > Install, makes them load.
$fontKey = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
if (-not (Get-ItemProperty $fontKey -Name 'JetBrainsMono NFP Regular (TrueType)' -ErrorAction SilentlyContinue)) {
    $fontDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
    $shellFonts = (New-Object -ComObject Shell.Application).Namespace(0x14)
    Get-ChildItem "$env:USERPROFILE\scoop\apps\JetBrainsMono-NF-Propo\current" -Filter '*NerdFontPropo-*.ttf' | ForEach-Object {
        # drop scoop's copy so the Shell doesn't stop on an "already installed" prompt
        Remove-Item "$fontDir\$($_.Name)" -Force -ErrorAction SilentlyContinue
        $shellFonts.CopyHere($_.FullName, 0x14)
    }
    Write-Host "JetBrainsMono NFP fonts registered with Windows."
} else {
    Write-Host "JetBrainsMono NFP fonts already registered - skipping."
}

# 4. Create startup shortcuts
# Disable Windows artificial startup delay and idle-state waiting so startup apps launch immediately
$serializeKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize'
if (-not (Test-Path $serializeKey)) {
    New-Item -Path $serializeKey -Force | Out-Null
}
Set-ItemProperty -Path $serializeKey -Name 'StartupDelayInMSec' -Value 0 -Type DWord
Set-ItemProperty -Path $serializeKey -Name 'WaitForIdleState' -Value 0 -Type DWord

New-StartupShortcut -Name "win-hotkeys" `
                    -TargetPath (Join-Path $PSScriptRoot "win.ahk") `
                    -WorkingDirectory $PSScriptRoot

# PowerToys natively manages background startup via Windows Task Scheduler ("\PowerToys\Autorun for <User>").
# A duplicate shortcut in shell:startup causes PowerToys to run twice on login, forcing its settings window to open.
# Remove any existing startup shortcut and configure it to run silently in the background on startup.
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

# Prefer komorebic-no-console to avoid flashing a terminal on startup; fall back to komorebic
$komorebiExe = if (Get-Command komorebic-no-console -ErrorAction SilentlyContinue) { "komorebic-no-console" } else { "komorebic" }

foreach ($entry in @(
    @{ Name = "komorebi"; Exe = $komorebiExe; Args = "start --whkd" },
    @{ Name = "yasb";     Exe = "yasb";      Args = "" }
)) {
    $exePath = (Get-Command $entry.Exe -ErrorAction SilentlyContinue).Source
    if ($exePath) {
        New-StartupShortcut -Name $entry.Name -TargetPath $exePath -Arguments $entry.Args
    } else {
        Write-Warning "$($entry.Exe) not found in PATH - skipping startup shortcut."
    }
}

# 5. Wire up symlinks for files that live outside $HOME
& "$PSScriptRoot\link.ps1"

# The bar imports theme.css (untracked, written by the bar's theme menu); start on Glass
$barTheme = "$PSScriptRoot\.config\yasb\theme.css"
if (-not (Test-Path $barTheme)) {
    Copy-Item "$PSScriptRoot\.config\yasb\themes\glass.css" $barTheme
    Write-Host "Bar theme set to Glass."
}

# 6. Start tiling environment if not already running
if (-not (Get-Process -Name "komorebi" -ErrorAction SilentlyContinue)) {
    Write-Host "Starting komorebi..."
    Start-Process $komorebiExe -ArgumentList "start --whkd" -NoNewWindow
}
if (-not (Get-Process -Name "yasb" -ErrorAction SilentlyContinue)) {
    Write-Host "Starting yasb..."
    Start-Process (Get-Command yasb).Source
}
$ptExe = Get-PowerToysPath
if ($ptExe -and -not (Get-Process -Name "PowerToys" -ErrorAction SilentlyContinue)) {
    Write-Host "Starting PowerToys..."
    Start-Process $ptExe -WorkingDirectory (Split-Path $ptExe)
}
$ahk = Join-Path $PSScriptRoot "win.ahk"
if ((Test-Path $ahk) -and -not (Get-Process -Name "AutoHotkey*" -ErrorAction SilentlyContinue)) {
    Write-Host "Starting AutoHotkey..."
    Start-Process $ahk
}
