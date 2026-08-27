[CmdletBinding()]
param(
    [ValidateSet('UltraLow', 'LowLatency', 'Stable')]
    [string]$Profile = 'LowLatency'
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
. (Join-Path $root 'Bridge-Common.ps1')

& (Join-Path $root 'Start-Bridge.ps1')
$address = Find-BridgeAddress
if (-not $address) { throw 'Could not locate the provisioned appliance. Run Install.ps1 first.' }

if ($Profile -eq 'UltraLow') {
    $buffer = '30000'
    $period = '10000'
}
elseif ($Profile -eq 'LowLatency') {
    $buffer = '60000'
    $period = '20000'
}
else {
    $buffer = '200000'
    $period = '50000'
}

$command = "sed -i -E 's/--pcm-buffer-time=[0-9]+/--pcm-buffer-time=$buffer/; s/--pcm-period-time=[0-9]+/--pcm-period-time=$period/' /etc/init.d/bluealsa-aplay && rc-service bluealsa-aplay restart"
$result = Invoke-BridgeCommand -Address $address -RemoteCommand @('sh', '-c', $command)
$result.Output | Out-Host
if ($result.ExitCode -ne 0) { throw 'Could not change the latency profile.' }
Write-Host "Latency profile set to $Profile. Audio playback restarted." -ForegroundColor Green
