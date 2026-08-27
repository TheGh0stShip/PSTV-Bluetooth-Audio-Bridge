[CmdletBinding()]
param([string]$Version = '1.1.1')

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$vmSource = Join-Path $repoRoot 'out\vm'
$releaseRoot = Join-Path $repoRoot 'out\release'
$bundleName = "PSTV-Bluetooth-Audio-Bridge-v$Version"
$bundle = Join-Path $releaseRoot $bundleName
$zip = Join-Path $releaseRoot "$bundleName.zip"

if (-not (Test-Path -LiteralPath (Join-Path $vmSource 'PSTV-Bluetooth-Audio-Bridge.vmdk'))) {
    throw 'Build the appliance before creating a release.'
}
if (Test-Path -LiteralPath $bundle) { Remove-Item -LiteralPath $bundle -Recurse -Force }
if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
New-Item -ItemType Directory -Force -Path $bundle,(Join-Path $bundle 'vm'),(Join-Path $bundle 'vita'),(Join-Path $bundle 'tools') | Out-Null

Copy-Item -LiteralPath (Join-Path $repoRoot 'README.md'),(Join-Path $repoRoot 'LICENSE'),(Join-Path $repoRoot 'THIRD_PARTY_NOTICES.md') -Destination $bundle
Copy-Item -LiteralPath (Join-Path $repoRoot 'docs') -Destination $bundle -Recurse
Copy-Item -Path (Join-Path $repoRoot 'installer\*.ps1') -Destination $bundle
Copy-Item -LiteralPath (Join-Path $repoRoot 'SETUP.cmd') -Destination $bundle
Copy-Item -LiteralPath (Join-Path $vmSource 'PSTV-Bluetooth-Audio-Bridge.vmx'),(Join-Path $vmSource 'PSTV-Bluetooth-Audio-Bridge.vmdk') -Destination (Join-Path $bundle 'vm')
Copy-Item -LiteralPath (Join-Path $repoRoot 'vita\vitabtfix.skprx'),(Join-Path $repoRoot 'vita\vitabtfix-3.60.skprx') -Destination (Join-Path $bundle 'vita')
Copy-Item -LiteralPath (Join-Path $repoRoot 'tools\plink.exe'),(Join-Path $repoRoot 'tools\PUTTY-LICENSE.html') -Destination (Join-Path $bundle 'tools')

$forbidden = Get-ChildItem -LiteralPath $bundle -Recurse -Force -File | Where-Object {
    $_.Name -match '\.(vmem|vmss|lck|log)$' -or $_.Name -match '^id_ed25519' -or
        $_.Name -in @('known_hosts', 'admin-password.txt', 'hostkey.txt')
}
if ($forbidden) { throw "Release contains forbidden private/runtime files: $($forbidden.FullName -join ', ')" }

$manifestLines = foreach ($file in Get-ChildItem -LiteralPath $bundle -Recurse -File | Sort-Object FullName) {
    $relative = $file.FullName.Substring($bundle.Length + 1).Replace('\','/')
    '{0}  {1}' -f (Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash.ToLowerInvariant(), $relative
}
[IO.File]::WriteAllLines((Join-Path $bundle 'SHA256SUMS.txt'), $manifestLines, [Text.UTF8Encoding]::new($false))

Push-Location $releaseRoot
try {
    & tar.exe -a -c -f $zip $bundleName
    if ($LASTEXITCODE -ne 0) { throw "Archive creation failed (exit $LASTEXITCODE)." }
}
finally { Pop-Location }

$zipHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $zip).Hash.ToLowerInvariant()
[IO.File]::WriteAllText((Join-Path $releaseRoot 'SHA256SUMS.txt'), "$zipHash  $([IO.Path]::GetFileName($zip))`n", [Text.UTF8Encoding]::new($false))
Write-Host "Release archive: $zip" -ForegroundColor Green
Write-Host "SHA-256: $zipHash"
