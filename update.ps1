git -C $PSScriptRoot pull origin main
# setup.ps1 is idempotent: installs anything new, then re-runs link.ps1
& "$PSScriptRoot\setup.ps1"
