[CmdletBinding()]
param([switch]$Force)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$vmx = Join-Path $root 'vm\PSTV-Bluetooth-Audio-Bridge.vmx'
$vmrun = @(
    'C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe',
    'C:\Program Files\VMware\VMware Workstation\vmrun.exe'
) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $vmrun) { throw 'VMware Workstation Pro is not installed.' }
if (-not (Test-Path -LiteralPath $vmx)) { throw "Appliance VM is missing: $vmx" }

$mode = if ($Force) { 'hard' } else { 'soft' }
& $vmrun -T ws stop $vmx $mode | Out-Null
if ($LASTEXITCODE -ne 0) { throw "VMware could not stop the appliance (exit $LASTEXITCODE)." }
Write-Host 'PSTV Bluetooth Audio Bridge stopped.' -ForegroundColor Green

