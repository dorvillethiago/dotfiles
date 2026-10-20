#Requires -RunAsAdministrator

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

# 2. Bare clone
if (Test-Path $gitDir) {
    Write-Host ".dotfiles already exists — skipping clone."
} else {
    git clone --bare $repo $gitDir
}

# 3. Checkout into $HOME, backing up any conflicting files first
$conflicts = Invoke-DotGit checkout 2>&1 | Select-String "^\s+\S" | ForEach-Object { $_.ToString().Trim() }
if ($conflicts) {
    $backup = "$HOME\.dotfiles-backup"
    Write-Warning "Backing up $($conflicts.Count) conflicting file(s) to $backup"
    foreach ($file in $conflicts) {
        $dest = Join-Path $backup $file
        New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
        Move-Item (Join-Path $HOME $file) $dest -Force
    }
    Invoke-DotGit checkout
}

# 4. Hide untracked files from dot-git status (keeps `git status` clean)
Invoke-DotGit config status.showUntrackedFiles no

# 5. Bootstrap the environment
& "$HOME\setup.ps1"
