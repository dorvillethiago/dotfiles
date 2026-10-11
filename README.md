# 1. Install Scoop via WinGet
winget install Scoop.Scoop --source winget --accept-source-agreements --accept-package-agreements

# 2. Refresh the PATH variable in the current session so 'scoop' is recognized
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# 3. Add the extras bucket required for these packages
scoop bucket add extras

# 4. Install Komorebi, its hotkey daemon, and YASB via Scoop
scoop install komorebi whkd yasb