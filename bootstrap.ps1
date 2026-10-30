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

function Assert-Git([string]$Step) {
    if ($LASTEXITCODE -ne 0) {
        Write-Error "git $Step failed (exit $LASTEXITCODE). Fix the error above and run bootstrap again."
        exit 1
    }
}

# 2. Bare clone (only on a fresh machine)
if (Test-Path $gitDir) {
    git --git-dir="$gitDir" rev-parse --git-dir *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "$gitDir exists but isn't a git repository (an interrupted clone?). Delete it and run bootstrap again."
        exit 1
    }
    Write-Host ".dotfiles already exists - skipping clone."
} else {
    git clone --bare $repo $gitDir
    Assert-Git "clone"
    # A bare clone has no remote-tracking branches or upstream; add both so fetch, pull and status work
    Invoke-DotGit config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
    Invoke-DotGit fetch origin
    Assert-Git "fetch"
    Invoke-DotGit branch --set-upstream-to=origin/main main
    Assert-Git "upstream setup"
}

# 3. Checkout into $HOME (marked done in the repo config, so a failed run resumes here)
if ((Invoke-DotGit config --get dotfiles.checkedout) -eq "true") {
    Write-Host "Dotfiles already checked out - skipping."
} else {
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
    Assert-Git "checkout"
    Invoke-DotGit config status.showUntrackedFiles no
    Invoke-DotGit config dotfiles.checkedout true
}

# 4. Bootstrap the environment
& "$HOME\setup.ps1"
