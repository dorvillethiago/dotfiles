if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Run this from an elevated PowerShell prompt."
    exit 1
}

$repo   = "https://github.com/dorvillethiago/dotfiles.git"
$gitDir = "$HOME\.dotfiles"

function Update-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User")
}

function Invoke-DotGit { git --git-dir="$gitDir" --work-tree="$HOME" @args }

# 1. Install git if missing
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Installing git..."
    winget install Git.Git --source winget --accept-source-agreements --accept-package-agreements
    Update-Path
}

# 2. Bare clone + checkout (only on a fresh machine)
if (Test-Path $gitDir) {
    Write-Host ".dotfiles already exists — skipping clone and checkout."
} else {
    git clone --bare $repo $gitDir

    # Back up any conflicting files before checkout
    $conflicts = Invoke-DotGit checkout 2>&1 | Select-String "^\s+\S" | ForEach-Object { $_.ToString().Trim() }
    if ($conflicts) {
        $backup = "$HOME\.dotfiles-backup"
        Write-Warning "Backing up $($conflicts.Count) conflicting file(s) to $backup"
        foreach ($file in $conflicts) {
            $dest = Join-Path $backup $file
            New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
            Move-Item (Join-Path $HOME $file) $dest -Force
        }
    }
    Invoke-DotGit checkout
    Invoke-DotGit config status.showUntrackedFiles no
}

# 3. Bootstrap the environment
& "$HOME\setup.ps1"