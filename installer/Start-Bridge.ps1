[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$vmx = Join-Path $root 'vm\PSTV-Bluetooth-Audio-Bridge.vmx'
$configPath = Join-Path $root 'config\install.json'
$logDir = Join-Path $root 'logs'
$logPath = Join-Path $logDir 'host.log'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

function Write-BridgeLog([string]$Message) {
    $line = '{0:u} {1}' -f (Get-Date), $Message
    Add-Content -LiteralPath $logPath -Value $line -Encoding UTF8
    Write-Host $Message
}

$vmrunCandidates = @(
    'C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe',
    'C:\Program Files\VMware\VMware Workstation\vmrun.exe'
)
$vmrun = $vmrunCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $vmrun) {
    throw 'VMware Workstation Pro is not installed. See docs\QUICKSTART.md.'
}
if (-not (Test-Path -LiteralPath $vmx)) {
    throw "Appliance VM is missing: $vmx"
}

if (Test-Path -LiteralPath $configPath) {
    $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
    foreach ($adapterName in @($config.disabledWiFiAdapters)) {
        $adapter = Get-NetAdapter -Name $adapterName -ErrorAction SilentlyContinue
        if ($adapter -and $adapter.Status -ne 'Disabled') {
            Disable-NetAdapter -Name $adapterName -Confirm:$false
            Write-BridgeLog "Disabled the configured Wi-Fi adapter '$adapterName' to protect Bluetooth airtime."
        }
    }
}

$resolvedVmx = (Resolve-Path -LiteralPath $vmx).Path
$running = @(& $vmrun -T ws list 2>$null)
if ($running -notcontains $resolvedVmx) {
    Write-BridgeLog 'Starting the PSTV Bluetooth Audio Bridge appliance.'
    & $vmrun -T ws start $resolvedVmx nogui | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "VMware could not start the bridge (exit $LASTEXITCODE)."
    }
}
else {
    Write-BridgeLog 'The PSTV Bluetooth Audio Bridge appliance is already running.'
}

$deadline = (Get-Date).AddSeconds(30)
do {
    $vmProcess = Get-CimInstance Win32_Process -Filter "Name='vmware-vmx.exe'" |
        Where-Object { $_.CommandLine -like '*PSTV-Bluetooth-Audio-Bridge.vmx*' } |
        Select-Object -First 1
    if ($vmProcess) {
        try {
            (Get-Process -Id $vmProcess.ProcessId).PriorityClass = 'High'
            Write-BridgeLog 'Bridge process priority is High.'
        }
        catch {
            Write-BridgeLog "Could not raise process priority: $($_.Exception.Message)"
        }
        break
    }
    Start-Sleep -Milliseconds 500
} while ((Get-Date) -lt $deadline)

