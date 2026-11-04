function Update-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User")
}

function Get-PowerToysPath {
    $candidates = @(
        "$env:USERPROFILE\scoop\apps\powertoys\current\PowerToys.exe",
        "$env:SCOOP\apps\powertoys\current\PowerToys.exe",
        "$env:SCOOP_GLOBAL\apps\powertoys\current\PowerToys.exe",
        "$env:ProgramData\scoop\apps\powertoys\current\PowerToys.exe",
        "$env:ProgramFiles\PowerToys\PowerToys.exe",
        "${env:ProgramFiles(x86)}\PowerToys\PowerToys.exe",
        "$env:LOCALAPPDATA\Programs\PowerToys\PowerToys.exe"
    )
    foreach ($path in $candidates) {
        if ($path -and (Test-Path $path)) { return $path }
    }
    return $null
}

function Set-StartupShortcut {
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
