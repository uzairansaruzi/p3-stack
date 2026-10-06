# Install p3-stack skills for T3 Code on Windows.
# Uses directory junctions: no admin rights or Developer Mode needed.
[CmdletBinding()]
param(
    [string]$Project
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$target = Join-Path $HOME '.agents\skills'
if ($Project) {
    $target = Join-Path $Project '.agents\skills'
}
# .NET resolves relative paths against the process directory, not the PowerShell location.
$target = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($target)

New-Item -ItemType Directory -Force -Path $target | Out-Null
$installed = 0
$skipped = 0

foreach ($skill in Get-ChildItem -Directory -Path (Join-Path $PSScriptRoot 'skills')) {
    $link = Join-Path $target $skill.Name
    $existing = Get-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue
    if ($existing -and $existing.LinkType) {
        # Non-recursive delete removes only the link, never the skill it points to.
        [System.IO.Directory]::Delete($link)
    } elseif ($existing) {
        Write-Output "skip $($skill.Name) (exists and is not a link)"
        $skipped++
        continue
    }
    New-Item -ItemType Junction -Path $link -Target $skill.FullName | Out-Null
    $installed++
}

$summary = "linked $installed skills into $target"
if ($skipped -gt 0) {
    $summary += " ($skipped skipped)"
}
Write-Output $summary
