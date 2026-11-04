$scripts = $PSScriptRoot
. "$scripts\utils.ps1"

# 1. Install Scoop if missing
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Scoop..."
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
    Update-Path
} else {
    Write-Host "Scoop already installed - skipping."
}

# 2. Add required buckets
$buckets = @("extras", "nerd-fonts")
$installedBuckets = scoop bucket list
foreach ($bucket in $buckets) {
    if (-not ($installedBuckets | Select-String $bucket)) {
        Write-Host "Adding Scoop bucket '$bucket'..."
        scoop bucket add $bucket
    }
}

# 3. Install packages (tiling and bar tools are version-pinned)
$packages = @(
    @{ Name = "komorebi@0.1.41"; Check = { Get-Command komorebic -ErrorAction SilentlyContinue } },
    @{ Name = "whkd@0.2.10";     Check = { Get-Command whkd -ErrorAction SilentlyContinue } },
    @{ Name = "yasb@2.0.7";       Check = { Get-Command yasb -ErrorAction SilentlyContinue } },
    @{ Name = "autohotkey";       Check = { Get-Command autohotkey -ErrorAction SilentlyContinue } },
    @{ Name = "powertoys@0.102.3001.0"; Check = { (Get-PowerToysPath) -ne $null } },
    @{ Name = "pwsh";             Check = { Get-Command pwsh -ErrorAction SilentlyContinue } },
    @{ Name = "starship";         Check = { Get-Command starship -ErrorAction SilentlyContinue } },
    @{ Name = "fastfetch";        Check = { Get-Command fastfetch -ErrorAction SilentlyContinue } },
    @{ Name = "JetBrainsMono-NF"; Check = { (Test-Path "$env:LOCALAPPDATA\Microsoft\Windows\Fonts\JetBrainsMonoNerdFont-*.ttf") -or (Test-Path "$env:windir\Fonts\JetBrainsMonoNerdFont-*.ttf") } },
    @{ Name = "JetBrainsMono-NF-Propo"; Check = { (Test-Path "$env:LOCALAPPDATA\Microsoft\Windows\Fonts\JetBrainsMonoNerdFontPropo-*.ttf") -or (Test-Path "$env:windir\Fonts\JetBrainsMonoNerdFontPropo-*.ttf") } }
)

foreach ($pkg in $packages) {
    if (& $pkg.Check) {
        Write-Host "$($pkg.Name) already installed - skipping."
    } else {
        Write-Host "Installing $($pkg.Name)..."
        scoop install $pkg.Name
    }
}
Update-Path

# 4. Hold core packages so 'scoop update *' never breaks configs
@("komorebi", "whkd", "yasb", "powertoys") | ForEach-Object { scoop hold $_ 2>$null }
