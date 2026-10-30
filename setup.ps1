function Update-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User")
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
    if (Test-Path $lnk) { Write-Host "$Name shortcut already exists - skipping."; return }

    $WshShell = New-Object -ComObject WScript.Shell
    $shortcut  = $WshShell.CreateShortcut($lnk)
    $shortcut.TargetPath = $TargetPath
    if ($Arguments)        { $shortcut.Arguments       = $Arguments }
    if ($WorkingDirectory) { $shortcut.WorkingDirectory = $WorkingDirectory }
    $shortcut.Save()
    Write-Host "$Name startup shortcut created."
}

# 1. Install Scoop
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    winget install Scoop.Scoop --source winget --accept-source-agreements --accept-package-agreements
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
    @{ Name = "komorebi";   Check = { Get-Command komorebic -ErrorAction SilentlyContinue } },
    @{ Name = "whkd";       Check = { Get-Command whkd -ErrorAction SilentlyContinue } },
    @{ Name = "yasb";       Check = { Get-Command yasb -ErrorAction SilentlyContinue } },
    @{ Name = "autohotkey"; Check = { Get-Command autohotkey -ErrorAction SilentlyContinue } },
    @{ Name = "powertoys";  Check = { Test-Path "$env:LOCALAPPDATA\Microsoft\PowerToys" } },
    @{ Name = "pwsh";       Check = { Get-Command pwsh -ErrorAction SilentlyContinue } },
    @{ Name = "starship";   Check = { Get-Command starship -ErrorAction SilentlyContinue } },
    @{ Name = "fastfetch";  Check = { Get-Command fastfetch -ErrorAction SilentlyContinue } },
    @{ Name = "JetBrainsMono-NF"; Check = { (Test-Path "$env:LOCALAPPDATA\Microsoft\Windows\Fonts\JetBrainsMonoNerdFontPropo-*.ttf") -or (Test-Path "$env:windir\Fonts\JetBrainsMonoNerdFontPropo-*.ttf") } }
)
foreach ($pkg in $packages) {
    if (& $pkg.Check) {
        Write-Host "$($pkg.Name) already installed - skipping."
    } else {
        scoop install $pkg.Name
    }
}
Update-Path

# 4. Create startup shortcuts
New-StartupShortcut -Name "win-hotkeys" `
                    -TargetPath (Join-Path $PSScriptRoot "win.ahk") `
                    -WorkingDirectory $PSScriptRoot

foreach ($entry in @(
    @{ Name = "komorebi"; Exe = "komorebic"; Args = "start --await-configuration" },
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

# 6. Start tiling environment if not already running
if (-not (Get-Process -Name "komorebi" -ErrorAction SilentlyContinue)) {
    Write-Host "Starting komorebi..."
    Start-Process komorebic -ArgumentList "start --await-configuration" -NoNewWindow
}
if (-not (Get-Process -Name "yasb" -ErrorAction SilentlyContinue)) {
    Write-Host "Starting yasb..."
    Start-Process (Get-Command yasb).Source
}
$ptExe = Join-Path (scoop prefix powertoys) "PowerToys.exe"
if ((Test-Path $ptExe) -and -not (Get-Process -Name "PowerToys" -ErrorAction SilentlyContinue)) {
    Write-Host "Starting PowerToys..."
    Start-Process $ptExe
}
$ahk = Join-Path $PSScriptRoot "win.ahk"
if ((Test-Path $ahk) -and -not (Get-Process -Name "AutoHotkey*" -ErrorAction SilentlyContinue)) {
    Write-Host "Starting AutoHotkey..."
    Start-Process $ahk
}
