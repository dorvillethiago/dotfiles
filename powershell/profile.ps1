# fastfetch recoloured from the Windows accent palette, so it follows Settings -> Personalization -> Colors.
# The config's accent roles use unique colours (see .config/fastfetch/config.jsonc), swapped here on a temp copy.
function Show-Fastfetch {
    $config = "$HOME\.config\fastfetch\config.jsonc"
    $palette = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent' -ErrorAction SilentlyContinue).AccentPalette
    if (-not $palette -or $palette.Length -lt 32 -or -not (Test-Path $config)) { fastfetch @args; return }

    # AccentPalette is 8 RGBA shades, lightest first; 3 is the accent itself
    $rgb = { param($i) , @($palette[$i * 4], $palette[$i * 4 + 1], $palette[$i * 4 + 2]) }
    $ansi = { param($c) '38;2;{0};{1};{2}' -f $c[0], $c[1], $c[2] }
    $map = [ordered]@{
        '38;2;148;203;137' = & $ansi (& $rgb 1)   # icons, user name, usage bars
        '38;2;221;159;211' = & $ansi (& $rgb 0)   # host name
        '38;2;152;187;219' = & $ansi (& $rgb 0)   # section label
    }
    # Logo rows, top to bottom: blend shade 1 into shade 4
    $logoRows = '176;208;238', '160;197;232', '144;186;226', '128;175;220', '112;163;214', '98;152;207', '86;141;200'
    $from, $to = (& $rgb 1), (& $rgb 4)
    for ($row = 0; $row -lt $logoRows.Count; $row++) {
        $t = $row / ($logoRows.Count - 1)
        $map["38;2;$($logoRows[$row])"] = & $ansi (0..2 | ForEach-Object { [int]($from[$_] + ($to[$_] - $from[$_]) * $t) })
    }

    $text = Get-Content $config -Raw
    foreach ($key in $map.Keys) { $text = $text.Replace($key, $map[$key]) }
    $themed = Join-Path $env:TEMP "fastfetch-accent.jsonc"
    Set-Content $themed $text -Encoding ascii -NoNewline
    fastfetch -c $themed @args
}

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
    if ($width -ge 82) { Show-Fastfetch }
    elseif ($width -ge 60) { Show-Fastfetch --logo none }
    Remove-Variable width, stable, i
}
Remove-Variable scripted

Invoke-Expression (&starship init powershell)
