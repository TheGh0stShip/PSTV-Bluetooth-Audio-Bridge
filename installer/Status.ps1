[CmdletBinding()]
param([switch]$Diagnostics)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$vmx = Join-Path $root 'vm\PSTV-Bluetooth-Audio-Bridge.vmx'
. (Join-Path $root 'Bridge-Common.ps1')
$vmrun = @(
    'C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe',
    'C:\Program Files\VMware\VMware Workstation\vmrun.exe'
) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1

$task = Get-ScheduledTask -TaskName 'PSTV Bluetooth Audio Bridge' -ErrorAction SilentlyContinue
Write-Host ('Autostart task : {0}' -f $(if ($task) { $task.State } else { 'not installed' }))
if (-not $vmrun -or -not (Test-Path -LiteralPath $vmx)) {
    Write-Host 'Appliance      : unavailable'
    exit 1
}

$resolvedVmx = (Resolve-Path -LiteralPath $vmx).Path
$running = @(& $vmrun -T ws list 2>$null) -contains $resolvedVmx
Write-Host ('Appliance      : {0}' -f $(if ($running) { 'running' } else { 'stopped' }))
if (-not $running) { exit 1 }

if (-not (Test-Path -LiteralPath (Join-Path $root 'config\admin-password.txt'))) {
    Write-Host 'Provisioning   : incomplete'
    exit 1
}

$address = Find-BridgeAddress
if (-not $address) {
    Write-Host 'Guest address  : not discovered'
    exit 1
}
Write-Host "Guest address  : $address"
$remoteCommand = if ($Diagnostics) { 'pstv-diagnose' } else { 'pstv-status' }
$result = Invoke-BridgeCommand -Address $address -RemoteCommand @($remoteCommand)
$result.Output | Out-Host
exit $result.ExitCode
