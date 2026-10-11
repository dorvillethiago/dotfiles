function Update-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User")
}

function New-StartupShortcut {
    param(
        [string]$Name,
        [string]$TargetPath,
        [string]$Arguments      = "",
        [string]$WorkingDirectory = ""
    )

    $startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    $WshShell      = New-Object -ComObject WScript.Shell
    $shortcut      = $WshShell.CreateShortcut("$startupFolder\$Name.lnk")
    $shortcut.TargetPath = $TargetPath
    if ($Arguments)       { $shortcut.Arguments       = $Arguments }
    if ($WorkingDirectory){ $shortcut.WorkingDirectory = $WorkingDirectory }
    $shortcut.Save()
    Write-Host "$Name startup shortcut created."
}

# 1. Install Scoop
winget install Scoop.Scoop --source winget --accept-source-agreements --accept-package-agreements
Update-Path

# 2. Add extras bucket and install packages
scoop bucket add extras
scoop install komorebi whkd yasb autohotkey powertoys
Update-Path

# 3. Create startup shortcuts
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
        Write-Warning "$($entry.Exe) not found in PATH — skipping startup shortcut."
    }
}
