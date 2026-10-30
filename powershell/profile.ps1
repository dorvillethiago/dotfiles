# System info on new interactive shells only, not for scripts or `pwsh -Command`
$scripted = [Environment]::GetCommandLineArgs() -match '^-(c|command|f|file|noni|noninteractive)$'
if (-not $scripted -and -not [Console]::IsOutputRedirected -and (Get-Command fastfetch -ErrorAction SilentlyContinue)) {
    # komorebi tiles new windows right after they open, and output printed before
    # that gets re-wrapped by the terminal, so wait for the width to settle (max ~1s)
    $width = [Console]::WindowWidth
    $stable = 0
    for ($i = 0; $i -lt 20 -and $stable -lt 3; $i++) {
        Start-Sleep -Milliseconds 50
        if ([Console]::WindowWidth -eq $width) { $stable++ } else { $width = [Console]::WindowWidth; $stable = 0 }
    }
    # Full layout needs ~82 columns, the info alone ~60; narrower tiles get nothing
    if ($width -ge 82) { fastfetch }
    elseif ($width -ge 60) { fastfetch --logo none }
    Remove-Variable width, stable, i
}
Remove-Variable scripted

Invoke-Expression (&starship init powershell)
