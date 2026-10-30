# bootstrap.ps1 keeps git's data in ~\.dotfiles with $HOME as the work tree;
# a plain clone into $HOME has a normal .git folder instead
if (Test-Path "$PSScriptRoot\.git") {
    $git = @("-C", $PSScriptRoot)
} else {
    $git = @("--git-dir=$HOME\.dotfiles", "--work-tree=$HOME")
    # Bare clones made before bootstrap set this up have no remote-tracking branches
    if (-not (git @git config --get remote.origin.fetch)) {
        git @git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
    }
}

git @git pull origin main
if ($LASTEXITCODE -ne 0) {
    Write-Error "git pull failed (exit $LASTEXITCODE). Fix the error above and run update again."
    exit 1
}

# setup.ps1 is idempotent: installs anything new, then re-runs link.ps1
& "$PSScriptRoot\setup.ps1"
