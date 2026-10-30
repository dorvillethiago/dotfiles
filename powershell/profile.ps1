# Bootstrapped machines keep the dotfiles repo bare in ~\.dotfiles: `dotgit status`, `dotgit add`, ...
if ((Test-Path "$HOME\.dotfiles") -and -not (Test-Path "$HOME\.git")) {
    function dotgit { git --git-dir="$HOME\.dotfiles" --work-tree="$HOME" @args }
}

# Windows accent palette: 8 RGBA shades, lightest first; 3 is the accent itself. It follows
# Settings -> Personalization -> Colors, including an accent Windows picks from the wallpaper.
# Read via .NET: Get-ItemProperty loads the registry provider, ~400ms on a fresh shell
$accent = [Microsoft.Win32.Registry]::GetValue('HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent', 'AccentPalette', $null)
if ($accent.Length -lt 32) { $accent = $null }
function Get-AccentHex([int]$Shade) { '#{0:X2}{1:X2}{2:X2}' -f $accent[$Shade * 4], $accent[$Shade * 4 + 1], $accent[$Shade * 4 + 2] }
function Get-AccentAnsi([int]$Shade) { '38;2;{0};{1};{2}' -f $accent[$Shade * 4], $accent[$Shade * 4 + 1], $accent[$Shade * 4 + 2] }

# Copies a config to %TEMP% with colours swapped, so the repo's copy never changes; returns the copy's path
function Copy-Recoloured([string]$Path, [System.Collections.IDictionary]$Map) {
    $text = Get-Content $Path -Raw
    foreach ($key in $Map.Keys) { $text = $text.Replace($key, $Map[$key]) }
    $copy = Join-Path $env:TEMP ("accent-" + (Split-Path $Path -Leaf))
    Set-Content $copy $text -Encoding utf8 -NoNewline
    $copy
}

# fastfetch: the config's accent roles use colours unique to them (see .config/fastfetch/config.jsonc)
function Show-Fastfetch {
    $config = "$HOME\.config\fastfetch\config.jsonc"
    if (-not $accent -or -not (Test-Path $config)) { fastfetch @args; return }

    $map = [ordered]@{
        '38;2;148;203;137' = Get-AccentAnsi 1   # icons, user name, usage bars
        '38;2;221;159;211' = Get-AccentAnsi 0   # host name
        '38;2;152;187;219' = Get-AccentAnsi 0   # section label
    }
    # Logo rows, top to bottom: blend shade 1 into shade 4
    $logoRows = '176;208;238', '160;197;232', '144;186;226', '128;175;220', '112;163;214', '98;152;207', '86;141;200'
    $from = $accent[4..6]
    $to = $accent[16..18]
    for ($row = 0; $row -lt $logoRows.Count; $row++) {
        $t = $row / ($logoRows.Count - 1)
        $mix = 0..2 | ForEach-Object { [int]($from[$_] + ($to[$_] - $from[$_]) * $t) }
        $map["38;2;$($logoRows[$row])"] = '38;2;{0};{1};{2}' -f $mix
    }
    fastfetch -c (Copy-Recoloured $config $map) @args
}

# System info on new interactive shells only, not for scripts or `pwsh -Command`
$scripted = [Environment]::GetCommandLineArgs() -match '^-(c|command|f|file|noni|noninteractive)$'
$interactive = -not $scripted -and -not [Console]::IsOutputRedirected
if ($interactive -and (Get-Command fastfetch -ErrorAction SilentlyContinue)) {
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

if ($accent) {
    # Starship: path and prompt arrow (green) and git branch (pink) follow the accent
    $starship = "$HOME\.config\starship.toml"
    if (Test-Path $starship) {
        $env:STARSHIP_CONFIG = Copy-Recoloured $starship ([ordered]@{ '#94CB89' = Get-AccentHex 1; '#DD9FD3' = Get-AccentHex 0 })
    }
    # Terminal cursor (OSC 12); the colour scheme's cursorColor stays as the fallback
    if ($interactive) { Write-Host -NoNewline "`e]12;$(Get-AccentHex 1)`a" }
}
Remove-Variable scripted, interactive

Invoke-Expression (&starship init powershell)
