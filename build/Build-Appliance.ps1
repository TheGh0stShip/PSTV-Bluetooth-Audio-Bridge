[CmdletBinding()]
param([string]$Distribution = 'Ubuntu')

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$drive = $repoRoot.Substring(0, 1).ToLowerInvariant()
$relativePath = $repoRoot.Substring(3).Replace('\', '/')
$linuxPath = "/mnt/$drive/$relativePath"

Write-Host 'Building the sanitized Alpine appliance. This can take several minutes.' -ForegroundColor Cyan
& wsl.exe -d $Distribution -u root -- bash "$linuxPath/build/build-appliance.sh"
if ($LASTEXITCODE -ne 0) { throw "Appliance build failed (exit $LASTEXITCODE)." }
