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

# 2. Add extras bucket
if (-not (scoop bucket list | Select-String "extras")) {
    scoop bucket add extras
}

# 3. Install packages
$packages = @(
    @{ Name = "komorebi";   Check = { Get-Command komorebic -ErrorAction SilentlyContinue } },
    @{ Name = "whkd";       Check = { Get-Command whkd -ErrorAction SilentlyContinue } },
    @{ Name = "yasb";       Check = { Get-Command yasb -ErrorAction SilentlyContinue } },
    @{ Name = "autohotkey"; Check = { Get-Command autohotkey -ErrorAction SilentlyContinue } },
    @{ Name = "powertoys";  Check = { Test-Path "$env:LOCALAPPDATA\Microsoft\PowerToys" } }
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
