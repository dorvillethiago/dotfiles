# 1. Install Scoop via WinGet
winget install Scoop.Scoop --source winget --accept-source-agreements --accept-package-agreements

# 2. Refresh the PATH variable in the current session so 'scoop' is recognized
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# 3. Add the extras bucket required for these packages
scoop bucket add extras

# 4. Install Komorebi, its hotkey daemon, and YASB via Scoop
scoop install komorebi whkd yasb autohotkey powertoyss

# 5. Create a shortcut for win.ahk in the Windows Startup folder
$ahkScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "win.ahk"
$startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$shortcutPath = Join-Path -Path $startupFolder -ChildPath "win-hotkeys.lnk"

$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = $ahkScriptPath
$Shortcut.WorkingDirectory = $PSScriptRoot # Ensures AHK runs with this folder as its working directory
$Shortcut.Save()