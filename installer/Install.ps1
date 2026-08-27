[CmdletBinding()]
param(
    [string]$BluetoothHardwareId,
    [switch]$SkipPairing
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
$releaseVersion = '1.1.1'
$taskName = 'PSTV Bluetooth Audio Bridge'
$root = $PSScriptRoot
$vmx = Join-Path $root 'vm\PSTV-Bluetooth-Audio-Bridge.vmx'
$configDir = Join-Path $root 'config'
$configPath = Join-Path $configDir 'install.json'
$passwordFile = Join-Path $configDir 'admin-password.txt'
$hostKeyFile = Join-Path $configDir 'hostkey.txt'
$startScript = Join-Path $root 'Start-Bridge.ps1'
. (Join-Path $root 'Bridge-Common.ps1')

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $PSCommandPath))
    if ($BluetoothHardwareId) { $arguments += @('-BluetoothHardwareId', ('"{0}"' -f $BluetoothHardwareId)) }
    if ($SkipPairing) { $arguments += '-SkipPairing' }
    $elevated = Start-Process -FilePath 'powershell.exe' -ArgumentList ($arguments -join ' ') -Verb RunAs -Wait -PassThru
    exit $elevated.ExitCode
}

function Find-Vmrun {
    @(
        'C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe',
        'C:\Program Files\VMware\VMware Workstation\vmrun.exe'
    ) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
}

function Get-BluetoothRadios {
    $items = foreach ($device in Get-CimInstance Win32_PnPEntity) {
        if ($device.Service -ne 'BTHUSB') { continue }
        if ($device.PNPDeviceID -notmatch '^USB\\VID_([0-9A-Fa-f]{4})&PID_([0-9A-Fa-f]{4})') { continue }
        [pscustomobject]@{
            Name       = $device.Name
            HardwareId = $device.PNPDeviceID
            Vid        = $Matches[1].ToLowerInvariant()
            Pid        = $Matches[2].ToLowerInvariant()
        }
    }
    @($items | Sort-Object Vid, Pid -Unique)
}

function Set-VmxProperty([string]$Path, [string]$Name, [string]$Value) {
    $lines = [Collections.Generic.List[string]]::new()
    $pattern = '^(?i)' + [regex]::Escape($Name) + '\s*='
    foreach ($line in [IO.File]::ReadAllLines($Path)) {
        if ($line -notmatch $pattern) { $lines.Add($line) }
    }
    $lines.Add(('{0} = "{1}"' -f $Name, $Value.Replace('"', '\"')))
    [IO.File]::WriteAllLines($Path, $lines, [Text.UTF8Encoding]::new($false))
}

Write-Host ''
Write-Host 'PSTV Bluetooth Audio Bridge installer' -ForegroundColor Cyan
Write-Host '=====================================' -ForegroundColor Cyan

$vmrun = Find-Vmrun
if (-not $vmrun) {
    throw 'VMware Workstation Pro 17.5.2 or newer is required. See docs\QUICKSTART.md for the official free download.'
}
if (-not (Test-Path -LiteralPath $vmx) -or -not (Test-Path -LiteralPath $startScript)) {
    throw 'This installer must be run from the complete release bundle. The vm or host scripts are missing.'
}

$usbService = Get-Service -Name 'VMUSBArbService' -ErrorAction SilentlyContinue
if (-not $usbService) { throw 'VMware USB Arbitration Service is not installed.' }
if ($usbService.Status -ne 'Running') { Start-Service -Name $usbService.Name }

$radios = Get-BluetoothRadios
if ($BluetoothHardwareId) {
    $radio = $radios | Where-Object { $_.HardwareId -eq $BluetoothHardwareId -or $_.HardwareId -like "$BluetoothHardwareId*" } | Select-Object -First 1
    if (-not $radio) { throw "Bluetooth adapter not found: $BluetoothHardwareId" }
}
elseif ($radios.Count -eq 1) {
    $radio = $radios[0]
}
elseif ($radios.Count -gt 1) {
    Write-Host 'Choose the Bluetooth adapter VMware should dedicate to the PSTV bridge:'
    for ($index = 0; $index -lt $radios.Count; $index++) {
        Write-Host ('  [{0}] {1} (VID {2}, PID {3})' -f ($index + 1), $radios[$index].Name, $radios[$index].Vid, $radios[$index].Pid)
    }
    $selection = [int](Read-Host 'Adapter number')
    if ($selection -lt 1 -or $selection -gt $radios.Count) { throw 'Invalid Bluetooth adapter selection.' }
    $radio = $radios[$selection - 1]
}
else {
    throw 'No USB Bluetooth radio managed by the Windows BTHUSB driver was found.'
}

Write-Host ("Using Bluetooth adapter: {0} (VID {1}, PID {2})" -f $radio.Name, $radio.Vid, $radio.Pid) -ForegroundColor Green

New-Item -ItemType Directory -Force -Path $configDir | Out-Null
if (-not (Test-Path -LiteralPath $passwordFile)) {
    $randomBytes = New-Object byte[] 32
    $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($randomBytes) } finally { $rng.Dispose() }
    $password = [Convert]::ToBase64String($randomBytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
    [IO.File]::WriteAllText($passwordFile, $password + "`n", [Text.UTF8Encoding]::new($false))
}
$password = (Get-Content -LiteralPath $passwordFile -Raw).Trim()
if ($password.Length -lt 32) { throw 'The generated appliance credential is invalid. Delete config\admin-password.txt and rerun Install.ps1.' }
$encodedPassword = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($password))
if (Test-Path -LiteralPath $hostKeyFile) { Remove-Item -LiteralPath $hostKeyFile -Force }

Set-VmxProperty -Path $vmx -Name 'usb.autoConnect.device0' -Value ("vid:{0} pid:{1}" -f $radio.Vid, $radio.Pid)
Set-VmxProperty -Path $vmx -Name 'guestinfo.pstv_admin_password' -Value $encodedPassword
Set-VmxProperty -Path $vmx -Name 'guestinfo.pstv_release' -Value $releaseVersion

$wifiAdapters = @(Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object {
    $_.InterfaceDescription -match 'Wi-Fi|Wireless|802\.11' -or $_.Name -match 'Wi-?Fi|Wireless'
})
foreach ($wifi in $wifiAdapters) {
    if ($wifi.Status -eq 'Up') {
        Write-Host "Wi-Fi adapter '$($wifi.Name)' remains enabled." -ForegroundColor Green
    }
}

$config = [ordered]@{
    version              = $releaseVersion
    installedAt          = (Get-Date).ToUniversalTime().ToString('o')
    bluetoothName        = $radio.Name
    bluetoothHardwareId  = $radio.HardwareId
    bluetoothVid         = $radio.Vid
    bluetoothPid         = $radio.Pid
    disabledWiFiAdapters = @()
}
$config | ConvertTo-Json | Set-Content -LiteralPath $configPath -Encoding UTF8

$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent().Name
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument ('-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "{0}"' -f $startScript)
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $currentUser
$trigger.Delay = 'PT15S'
$principal = New-ScheduledTaskPrincipal -UserId $currentUser -LogonType Interactive -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Hours 0) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null

& $startScript

Write-Host 'Waiting for the appliance to finish first-boot provisioning...'
$address = $null
$managementReady = $false
$deadline = (Get-Date).AddMinutes(3)
do {
    $address = Find-BridgeAddress
    if ($address) { $managementReady = $true; break }
    Start-Sleep -Seconds 3
} while ((Get-Date) -lt $deadline)
if (-not $managementReady) { throw 'The appliance booted, but secure first-boot provisioning did not complete.' }

if (-not $SkipPairing) {
    (Invoke-BridgeCommand -Address $address -RemoteCommand @('pstv-pairing-mode', '300')).Output | Out-Host
    Write-Host ''
    Write-Host 'On the PSTV:' -ForegroundColor Cyan
    Write-Host '  Settings > Devices > Bluetooth Devices > PLT Focus'
    Write-Host 'Select PLT Focus and accept pairing. The installer will detect it automatically.'
    Write-Host ''

    $paired = $false
    $deadline = (Get-Date).AddMinutes(5)
    do {
        try {
            $pairResult = Invoke-BridgeCommand -Address $address -RemoteCommand @('pstv-status', '--paired')
            if ($pairResult.ExitCode -eq 0 -and $pairResult.Output.Count -gt 0) { $paired = $true; break }
        }
        catch { }
        Start-Sleep -Seconds 3
    } while ((Get-Date) -lt $deadline)
    if (-not $paired) {
        Write-Warning 'Pairing was not detected within five minutes. Run Pair-PSTV.ps1 when ready.'
    }
}

Write-Host ''
Write-Host 'Installation complete.' -ForegroundColor Green
Write-Host 'The bridge starts automatically at logon and sends PSTV audio to the current Windows default output.'
Write-Host 'After a PSTV reboot, the appliance reconnects automatically (normally within 30 seconds).'
Write-Host 'Run Status.ps1 for health checks or Pair-PSTV.ps1 to pair later.'
