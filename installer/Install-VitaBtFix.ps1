[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^\d{1,3}(\.\d{1,3}){3}$')]
    [string]$VitaIp,
    [int]$Port = 1337,
    [switch]$Firmware360
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$pluginName = if ($Firmware360) { 'vitabtfix-3.60.skprx' } else { 'vitabtfix.skprx' }
$plugin = Join-Path $root "vita\$pluginName"
$backupDir = Join-Path $root 'config\vita-backups'
$curl = Join-Path $env:WINDIR 'System32\curl.exe'
if (-not (Test-Path -LiteralPath $plugin)) { throw "Release plugin is missing: $plugin" }
if (-not (Test-Path -LiteralPath $curl)) { throw 'Windows curl.exe is required.' }

New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$localConfig = Join-Path $backupDir "config-$stamp.txt"
$patchedConfig = Join-Path $backupDir "config-$stamp.patched.txt"
$baseUrl = 'ftp://{0}:{1}/ur0:/tai' -f $VitaIp, $Port

Write-Host 'In VitaShell, press SELECT to start the FTP server before continuing.' -ForegroundColor Cyan
& $curl --fail --silent --show-error "$baseUrl/config.txt" --output $localConfig
if ($LASTEXITCODE -ne 0) { throw 'Could not download ur0:tai/config.txt. Confirm VitaShell FTP and the IP address.' }

$lines = [Collections.Generic.List[string]]::new()
$lines.AddRange([string[]][IO.File]::ReadAllLines($localConfig))
if (-not ($lines -contains '*KERNEL')) { throw 'The downloaded taiHEN config has no *KERNEL section; no changes were uploaded.' }
if (-not ($lines -contains 'ur0:tai/vitabtfix.skprx')) {
    $kernelIndex = $lines.IndexOf('*KERNEL')
    $lines.Insert($kernelIndex + 1, 'ur0:tai/vitabtfix.skprx')
}
[IO.File]::WriteAllLines($patchedConfig, $lines, [Text.UTF8Encoding]::new($false))

if ($PSCmdlet.ShouldProcess("$VitaIp ur0:tai", 'Back up config.txt, upload VitaBtFix, and install its *KERNEL entry')) {
    & $curl --fail --silent --show-error -T $localConfig "$baseUrl/config.txt.pstv-bridge.bak"
    if ($LASTEXITCODE -ne 0) { throw 'Could not upload the remote config backup; installation stopped.' }
    & $curl --fail --silent --show-error -T $plugin "$baseUrl/vitabtfix.skprx"
    if ($LASTEXITCODE -ne 0) { throw 'Could not upload vitabtfix.skprx.' }
    & $curl --fail --silent --show-error -T $patchedConfig "$baseUrl/config.txt"
    if ($LASTEXITCODE -ne 0) { throw 'Could not upload the patched taiHEN config.' }
}

Write-Host 'VitaBtFix installed with local and on-console config backups.' -ForegroundColor Green
Write-Host 'Stop VitaShell FTP and reboot the PSTV before installing/pairing the bridge.'

