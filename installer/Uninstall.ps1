[CmdletBinding()]
param([switch]$RemoveConfiguration)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$configPath = Join-Path $root 'config\install.json'
$vmx = Join-Path $root 'vm\PSTV-Bluetooth-Audio-Bridge.vmx'
$vmrun = @(
    'C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe',
    'C:\Program Files\VMware\VMware Workstation\vmrun.exe'
) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1

Unregister-ScheduledTask -TaskName 'PSTV Bluetooth Audio Bridge' -Confirm:$false -ErrorAction SilentlyContinue
if ($vmrun -and (Test-Path -LiteralPath $vmx)) {
    & $vmrun -T ws stop $vmx soft 2>$null | Out-Null
}

if (Test-Path -LiteralPath $configPath) {
    $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
    foreach ($adapterName in @($config.disabledWiFiAdapters)) {
        $adapter = Get-NetAdapter -Name $adapterName -ErrorAction SilentlyContinue
        if ($adapter -and $adapter.Status -eq 'Disabled') {
            Enable-NetAdapter -Name $adapterName -Confirm:$false
            Write-Host "Re-enabled Wi-Fi adapter '$adapterName'."
        }
    }
}

if ($RemoveConfiguration) {
    $configDir = Join-Path $root 'config'
    if (Test-Path -LiteralPath $configDir) {
        Remove-Item -LiteralPath $configDir -Recurse -Force
        Write-Host 'Removed the generated credential and local configuration.'
    }
}

Write-Host 'PSTV Bluetooth Audio Bridge autostart has been removed and the appliance is stopped.' -ForegroundColor Green
Write-Host 'You can now delete this release folder if desired.'
