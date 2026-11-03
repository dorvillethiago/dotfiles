# Applies a bar theme: copies themes\<name>.css over theme.css, which styles.css imports.
# YASB notices the change and restyles the bar by itself. theme.css isn't tracked, so switching
# never shows up in git. Run from the bar's theme menu, or by hand: .\set-theme.ps1 amoled
param([Parameter(Mandatory)][string]$Name)

$source = Join-Path $PSScriptRoot "themes\$Name.css"
if (-not (Test-Path $source)) {
    $available = (Get-ChildItem (Join-Path $PSScriptRoot "themes") -Filter *.css).BaseName -join ", "
    throw "No theme '$Name'. Available: $available"
}
# Write the content (not Copy-Item) so YASB's file watcher always sees a modification
[IO.File]::WriteAllText((Join-Path $PSScriptRoot "theme.css"), [IO.File]::ReadAllText($source))
