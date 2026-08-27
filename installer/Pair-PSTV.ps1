[CmdletBinding()]
param([int]$TimeoutSeconds = 300)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
. (Join-Path $root 'Bridge-Common.ps1')
$vmrun = @(
    'C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe',
    'C:\Program Files\VMware\VMware Workstation\vmrun.exe'
) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $vmrun -or -not (Test-Path -LiteralPath (Join-Path $root 'config\admin-password.txt'))) { throw 'Run Install.ps1 first.' }

& (Join-Path $root 'Start-Bridge.ps1')
$address = Find-BridgeAddress
if (-not $address) { throw 'Could not locate the provisioned appliance. Run Status.ps1 -Diagnostics.' }
(Invoke-BridgeCommand -Address $address -RemoteCommand @('pstv-pairing-mode', "$TimeoutSeconds")).Output | Out-Host

Write-Host 'On the PSTV, open Settings > Devices > Bluetooth Devices and select PLT Focus.' -ForegroundColor Cyan
$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
do {
    $result = Invoke-BridgeCommand -Address $address -RemoteCommand @('pstv-status', '--paired')
    if ($result.ExitCode -eq 0 -and $result.Output.Count -gt 0) {
        Write-Host "Paired successfully: $($result.Output[0])" -ForegroundColor Green
        exit 0
    }
    Start-Sleep -Seconds 3
} while ((Get-Date) -lt $deadline)
throw 'Pairing timed out. See docs\TROUBLESHOOTING.md.'
