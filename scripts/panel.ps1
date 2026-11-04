# DWC Shell — Interactive Management Panel
# Usage: dwc

$esc = [char]27
. "$PSScriptRoot\utils.ps1"

# ── Helpers ──────────────────────────────────────────────────────────────────

function Write-Color([string]$Text, [string]$Ansi = '37') {
    Write-Host "$esc[${Ansi}m$Text$esc[0m" -NoNewline
}

function Write-ColorLine([string]$Text, [string]$Ansi = '37') {
    Write-Host "$esc[${Ansi}m$Text$esc[0m"
}

function Hide-Cursor  { Write-Host "$esc[?25l" -NoNewline }
function Show-Cursor  { Write-Host "$esc[?25h" -NoNewline }
function Clear-Screen { Write-Host "$esc[2J$esc[H" -NoNewline }

function Get-DaemonStatus([string]$Name) {
    [bool](Get-Process $Name -ErrorAction SilentlyContinue)
}

function Get-GitDir {
    if (Test-Path "$HOME\.dwc-shell")  { return "$HOME\.dwc-shell" }
    if (Test-Path "$HOME\.wdc-shell")  { return "$HOME\.wdc-shell" }
    if (Test-Path "$HOME\.dotfiles")   { return "$HOME\.dotfiles" }
    return $null
}

function Invoke-Git {
    $dir = Get-GitDir
    if (-not $dir) { Write-Warning "No dwc-shell repository found."; return }
    git --git-dir="$dir" --work-tree="$HOME" @args
}

function Wait-Key {
    Show-Cursor
    Write-Host ""
    Write-ColorLine '  Press Esc to return...' '90'
    while ($true) {
        $k = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown,IncludeKeyUp')
        if ($k.KeyDown -and ($k.VirtualKeyCode -in 27, 81)) { break } # Esc or q
    }
}

# ── Health Data ──────────────────────────────────────────────────────────────

function Get-HealthData {
    $gitDir = Get-GitDir

    $daemons = @(
        @{
            Name      = 'Komorebi'
            Process   = 'komorebi'
            Installed = [bool](Get-Command komorebi -ErrorAction SilentlyContinue)
        }
        @{
            Name      = 'WHKD'
            Process   = 'whkd'
            Installed = [bool](Get-Command whkd -ErrorAction SilentlyContinue)
        }
        @{
            Name      = 'YASB'
            Process   = 'yasb'
            Installed = [bool](Get-Command yasb -ErrorAction SilentlyContinue)
        }
        @{
            Name      = 'PowerToys'
            Process   = 'PowerToys'
            Installed = [bool](Get-PowerToysPath)
        }
        @{
            Name      = 'AutoHotkey'
            Process   = 'AutoHotkey64'
            Installed = [bool](Get-Command autohotkey, autohotkey64 -ErrorAction SilentlyContinue)
        }
    )
    foreach ($d in $daemons) {
        $d.Running = Get-DaemonStatus $d.Process
    }

    $dirty = $false
    $behind = 0
    if ($gitDir) {
        $statusOutput = git --git-dir="$gitDir" --work-tree="$HOME" status --porcelain 2>$null
        $dirty = [bool]$statusOutput

        $behindOutput = git --git-dir="$gitDir" --work-tree="$HOME" rev-list --count "HEAD..origin/main" 2>$null
        if ($LASTEXITCODE -eq 0 -and $behindOutput) {
            $behind = [int]$behindOutput
        }
    }

    return @{
        Daemons = $daemons
        Dirty   = $dirty
        Behind  = $behind
        GitDir  = $gitDir
    }
}

# ── Shared UI ────────────────────────────────────────────────────────────────

function Show-Header {
    Write-Host ""
    Write-ColorLine "  ┌──────────────────────────────────────────────────┐" '36'
    Write-ColorLine "  │   DWC Shell · Dorville Windows Custom Shell     │" '36'
    Write-ColorLine "  └──────────────────────────────────────────────────┘" '36'
    Write-Host ""
}

function Show-PageHeader([string]$Title) {
    Clear-Screen
    Show-Header
    Write-ColorLine "  ─── $Title ───" '36'
    Write-Host ""
}

function Render-MenuLines([int]$Selected, [array]$Items) {
    for ($i = 0; $i -lt $Items.Count; $i++) {
        # Pad to fixed width so shorter text overwrites longer previous text
        $label = $Items[$i].Label.PadRight(18)
        $hint  = $Items[$i].Hint
        if ($i -eq $Selected) {
            Write-Color '    ► ' '36'
            Write-Color $label '1;36'
            Write-Color $hint '90'
        } else {
            Write-Color '      ' '37'
            Write-Color $label '37'
            Write-Color $hint '90'
        }
        Write-Host "$esc[K"  # clear rest of line
    }

    Write-Host ""
    Write-ColorLine "  ↑/↓ navigate · Enter select · Esc quit$esc[K" '90'
}

# ── Screens ──────────────────────────────────────────────────────────────────

function Show-HomeScreen([int]$Selected, [array]$MenuItems) {
    Clear-Screen
    Hide-Cursor
    Show-Header

    $health = Get-HealthData

    foreach ($d in $health.Daemons) {
        if (-not $d.Installed) {
            $icon  = '✖'
            $color = '31'
            $state = 'not installed'
        } elseif ($d.Running) {
            $icon  = '●'
            $color = '32'
            $state = 'running'
        } else {
            $icon  = '○'
            $color = '33'
            $state = 'stopped'
        }
        $pad   = '.' * (22 - $d.Name.Length)
        Write-Color "    $icon " $color
        Write-Color "$($d.Name) " '37'
        Write-Color "$pad " '90'
        Write-ColorLine $state $color
    }

    Write-Host ""

    if ($health.GitDir) {
        $repoIcon  = if ($health.Dirty) { '⚠' } else { '✔' }
        $repoColor = if ($health.Dirty) { '33' } else { '32' }
        $repoState = if ($health.Dirty) { 'Modified files' } else { 'Clean' }
        Write-Color "    $repoIcon " $repoColor
        Write-ColorLine "Repo: $repoState" $repoColor

        if ($health.Behind -gt 0) {
            Write-Color '    ⚠ ' '33'
            Write-ColorLine "$($health.Behind) commit(s) behind origin/main" '33'
        } else {
            Write-Color '    ✔ ' '32'
            Write-ColorLine "Up to date with origin/main" '32'
        }
    }

    Write-Host ""
    Write-ColorLine '  ──────────────────────────────────────────────────' '90'
    Write-Host ""

    # Return the line where the menu starts so we can redraw just the menu
    $script:menuTop = [Console]::CursorTop

    Render-MenuLines $Selected $MenuItems
}

function Redraw-Menu([int]$Selected, [array]$MenuItems) {
    Hide-Cursor
    [Console]::SetCursorPosition(0, $script:menuTop)
    Render-MenuLines $Selected $MenuItems
}

function Show-UpdateScreen {
    Show-Cursor
    Show-PageHeader 'Update'

    Write-ColorLine '  Pulling latest changes and running setup...' '33'
    Write-Host ""

    & "$HOME\scripts\update.ps1"

    Wait-Key
}

function Show-HealthScreen {
    Show-PageHeader 'Health Report'

    $health = Get-HealthData

    Write-ColorLine '  Daemons' '1;37'
    Write-Host ""
    foreach ($d in $health.Daemons) {
        if (-not $d.Installed) {
            $icon  = '✖'
            $color = '31'
            $state = 'Not installed'
        } elseif ($d.Running) {
            $icon  = '✔'
            $color = '32'
            $state = 'Installed & Running'
        } else {
            $icon  = '⚠'
            $color = '33'
            $state = 'Installed (Stopped)'
        }
        Write-Color "    $icon " $color
        Write-ColorLine "$($d.Name): $state" $color
    }

    Write-Host ""

    Write-ColorLine '  Symlinks' '1;37'
    Write-Host ""
    $links = @(
        @{ Name = 'PowerShell profile'; Path = $PROFILE }
        @{ Name = 'Windows Terminal';   Path = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" }
    )
    foreach ($l in $links) {
        $item = Get-Item $l.Path -ErrorAction SilentlyContinue
        $isLink = $item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
        $icon  = if ($isLink) { '✔' } else { '✖' }
        $color = if ($isLink) { '32' } else { '31' }
        $state = if ($isLink) { 'Linked' } else { 'Not linked' }
        Write-Color "    $icon " $color
        Write-ColorLine "$($l.Name): $state" $color
    }

    Write-Host ""

    # Startup shortcuts
    Write-ColorLine '  Startup Shortcuts' '1;37'
    Write-Host ""
    $startup = [Environment]::GetFolderPath('Startup')
    $shortcuts = @('win-hotkeys', 'komorebi', 'yasb')
    foreach ($name in $shortcuts) {
        $lnk = Join-Path $startup "$name.lnk"
        $exists = Test-Path $lnk
        $icon  = if ($exists) { '✔' } else { '✖' }
        $color = if ($exists) { '32' } else { '31' }
        $state = if ($exists) { 'Present' } else { 'Missing' }
        Write-Color "    $icon " $color
        Write-ColorLine "$name.lnk: $state" $color
    }

    # PowerToys startup (managed via settings.json → Task Scheduler, not shell:startup)
    $ptStartup = $false
    $ptSettingsFile = "$env:LOCALAPPDATA\Microsoft\PowerToys\settings.json"
    if (Test-Path $ptSettingsFile) {
        try {
            $ptCfg = Get-Content $ptSettingsFile -Raw | ConvertFrom-Json
            $ptStartup = [bool]$ptCfg.startup
        } catch {}
    }
    $ptIcon  = if ($ptStartup) { '✔' } else { '✖' }
    $ptColor = if ($ptStartup) { '32' } else { '31' }
    $ptState = if ($ptStartup) { 'Enabled (Task Scheduler)' } else { 'Disabled' }
    Write-Color "    $ptIcon " $ptColor
    Write-ColorLine "PowerToys: $ptState" $ptColor

    Wait-Key
}

function Show-ResourceScreen {
    Clear-Screen
    Hide-Cursor

    # Drain any leftover key events from menu selection
    try {
        while ($Host.UI.RawUI.KeyAvailable) {
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown,IncludeKeyUp')
        }
    } catch {}

    $targets = @(
        @{ Name = 'Komorebi';   Filter = 'komorebi*' }
        @{ Name = 'WHKD';       Filter = 'whkd*' }
        @{ Name = 'YASB';       Filter = 'yasb*' }
        @{ Name = 'AutoHotkey'; Filter = 'AutoHotkey*' }
        @{ Name = 'PowerToys';  Filter = 'PowerToys*' }
    )

    $cores = [Environment]::ProcessorCount
    $prevCpu = @{}
    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    foreach ($t in $targets) {
        $procs = Get-Process -Name $t.Filter -ErrorAction SilentlyContinue
        foreach ($p in $procs) {
            $prevCpu[$p.Id] = $p.TotalProcessorTime.TotalMilliseconds
        }
    }

    $spinners = @('⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏')
    $frame = 0

    $runningLive = $true
    while ($runningLive) {
        $elapsedSec = $sw.Elapsed.TotalSeconds
        $sw.Restart()

        $results = @()
        $totalMB = 0
        $totalCpuPct = 0
        $currentCpu = @{}

        foreach ($t in $targets) {
            $procs = Get-Process -Name $t.Filter -ErrorAction SilentlyContinue
            $count = ($procs | Measure-Object).Count
            $ramMB = 0
            $procCpuPct = 0

            if ($procs) {
                $ramMB = [math]::Round(($procs | Measure-Object -Property WorkingSet64 -Sum).Sum / 1MB, 1)
                foreach ($p in $procs) {
                    $currMs = $p.TotalProcessorTime.TotalMilliseconds
                    $currentCpu[$p.Id] = $currMs
                    $prevMs = if ($prevCpu.ContainsKey($p.Id)) { $prevCpu[$p.Id] } else { $currMs }
                    $diffMs = [math]::Max(0, $currMs - $prevMs)
                    if ($elapsedSec -gt 0) {
                        $pct = ($diffMs / 1000) / ($elapsedSec * $cores) * 100
                        $procCpuPct += $pct
                    }
                }
            }
            $totalMB += $ramMB
            $totalCpuPct += $procCpuPct

            $results += [PSCustomObject]@{
                Name       = $t.Name
                Running    = ($count -gt 0)
                Count      = $count
                RamMB      = $ramMB
                CpuPercent = [math]::Round($procCpuPct, 1)
            }
        }
        $prevCpu = $currentCpu

        $totalSysBytes = [System.GC]::GetGCMemoryInfo().TotalAvailableMemoryBytes
        $totalSysMB = if ($totalSysBytes -gt 0) { $totalSysBytes / 1MB } else { 16384 }
        $ramPercent = [math]::Round(($totalMB / $totalSysMB) * 100, 2)
        $sysGB = [math]::Round($totalSysMB / 1024, 1)
        $totalCpuDisplay = [math]::Round($totalCpuPct, 1)

        $spinnerChar = $spinners[$frame % $spinners.Count]
        $frame++
        $timeStr = (Get-Date).ToString("HH:mm:ss")

        # Reposition to top-left of terminal screen
        try {
            [Console]::SetCursorPosition(0, 0)
        } catch {
            Write-Host "$esc[H" -NoNewline
        }

        Show-Header
        Write-Color "  ─── Resource Usage ─── " '36'
        Write-Color "$spinnerChar LIVE $timeStr" '1;32'
        Write-Host "$esc[K"
        Write-Host "$esc[K"

        Write-ColorLine "  Daemon                  RAM             CPU %          Status$esc[K" '1;37'
        Write-ColorLine "  ─────────────────────────────────────────────────────────────$esc[K" '90'

        foreach ($r in $results) {
            $daemonCol = if ($r.Count -gt 1) { "$($r.Name) ($($r.Count) procs)" } else { $r.Name }
            $daemonCol = $daemonCol.PadRight(22)

            $ramCol = "$($r.RamMB) MB".PadRight(16)
            $cpuCol = "$($r.CpuPercent)%".PadRight(15)

            if ($r.Running) {
                $statusText = 'running'
                $statusColor = '32'
            } else {
                $statusText = 'stopped'
                $statusColor = '33'
            }

            Write-Color "  $daemonCol" '37'
            Write-Color $ramCol '36'
            Write-Color $cpuCol '37'
            Write-ColorLine "$statusText$esc[K" $statusColor
        }

        Write-ColorLine "  ─────────────────────────────────────────────────────────────$esc[K" '90'
        Write-Host "$esc[K"
        Write-ColorLine "  DWC Shell Footprint:$esc[K" '1;37'
        Write-Color "    Total Memory:  " '37'
        Write-Color "$totalMB MB" '1;36'
        Write-ColorLine " (~$ramPercent% of $sysGB GB system RAM)$esc[K" '90'

        Write-Color "    Total CPU:     " '37'
        Write-Color "$totalCpuDisplay%" '1;36'
        Write-ColorLine " active CPU usage$esc[K" '90'

        Write-Host "$esc[K"
        Write-ColorLine "  Updating live · Press Esc to return...$esc[K" '90'

        for ($i = 0; $i -lt 10; $i++) {
            while ($Host.UI.RawUI.KeyAvailable) {
                $k = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown,IncludeKeyUp')
                if ($k.KeyDown -and ($k.VirtualKeyCode -in 27, 81)) {
                    $runningLive = $false
                    break
                }
            }
            if (-not $runningLive) { break }
            Start-Sleep -Milliseconds 100
        }
    }

    Show-Cursor
}

function Show-ChangelogScreen {
    Show-PageHeader 'Changelog'

    $logs = Invoke-Git log --oneline --decorate -15 2>$null
    if ($logs) {
        foreach ($line in $logs) {
            if ($line -match '^([a-f0-9]+)\s(.*)$') {
                Write-Color "    $($Matches[1]) " '33'
                Write-ColorLine $Matches[2] '37'
            } else {
                Write-ColorLine "    $line" '37'
            }
        }
    } else {
        Write-ColorLine '    No commits found.' '90'
    }

    Wait-Key
}

function Show-StatusScreen {
    Show-PageHeader 'Repository Status'

    $output = Invoke-Git status 2>$null
    if ($output) {
        foreach ($line in $output) {
            Write-ColorLine "    $line" '37'
        }
    } else {
        Write-ColorLine '    Working tree clean.' '32'
    }

    Wait-Key
}

function Show-CodeScreen {
    Show-PageHeader 'Open in VS Code'

    $gitDir = Get-GitDir
    if (Get-Process Code -ErrorAction SilentlyContinue) {
        Write-ColorLine '    ⚠ Close VS Code first, or the git panel will not see dwc-shell.' '33'
        Wait-Key
        return
    }

    Write-ColorLine '    Launching VS Code...' '32'
    $env:GIT_DIR = $gitDir; $env:GIT_WORK_TREE = $HOME
    try { code $HOME } finally { Remove-Item Env:GIT_DIR, Env:GIT_WORK_TREE }

    Wait-Key
}

# ── Main Loop ────────────────────────────────────────────────────────────────

$menuItems = @(
    @{ Label = 'Update';          Hint = 'Pull latest, run setup, reload Komorebi';  Action = 'Update' }
    @{ Label = 'Health Report';   Hint = 'Check daemons, symlinks, and startup';     Action = 'Health' }
    @{ Label = 'Resource Usage';  Hint = 'Memory and CPU consumption breakdown';     Action = 'Resources' }
    @{ Label = 'Changelog';       Hint = 'Show recent commits';                      Action = 'Changelog' }
    @{ Label = 'Status';          Hint = 'Show modified files in the repository';    Action = 'Status' }
    @{ Label = 'Open in VS Code'; Hint = 'Launch VS Code scoped to dwc-shell';       Action = 'Code' }
    @{ Label = 'Quit';            Hint = 'Exit the panel';                           Action = 'Quit' }
)

$selected    = 0
$running     = $true
$needsRedraw = $true

try {
    while ($running) {
        if ($needsRedraw) {
            Show-HomeScreen $selected $menuItems
            $needsRedraw = $false
        }

        $key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

        switch ($key.VirtualKeyCode) {
            38 { # Up arrow
                $selected = if ($selected -gt 0) { $selected - 1 } else { $menuItems.Count - 1 }
                Redraw-Menu $selected $menuItems
            }
            40 { # Down arrow
                $selected = if ($selected -lt ($menuItems.Count - 1)) { $selected + 1 } else { 0 }
                Redraw-Menu $selected $menuItems
            }
            13 { # Enter
                switch ($menuItems[$selected].Action) {
                    'Update'    { Show-UpdateScreen;    $needsRedraw = $true }
                    'Health'    { Show-HealthScreen;    $needsRedraw = $true }
                    'Resources' { Show-ResourceScreen;  $needsRedraw = $true }
                    'Changelog' { Show-ChangelogScreen; $needsRedraw = $true }
                    'Status'    { Show-StatusScreen;    $needsRedraw = $true }
                    'Code'      { Show-CodeScreen;      $needsRedraw = $true }
                    'Quit'      { $running = $false }
                }
            }
            27 { # Escape
                $running = $false
            }
        }
    }
} finally {
    Show-Cursor
    Clear-Screen
}
