Set-StrictMode -Version 2.0

function Get-BridgeDhcpAddresses {
    $leasePath = 'C:\ProgramData\VMware\vmnetdhcp.leases'
    if (-not (Test-Path -LiteralPath $leasePath)) { return @() }
    $leaseText = Get-Content -LiteralPath $leasePath -Raw
    $pattern = '(?ms)lease\s+(?<ip>\d{1,3}(?:\.\d{1,3}){3})\s+\{(?<body>[^}]*)\}'
    @([regex]::Matches($leaseText, $pattern) |
        Where-Object { $_.Groups['body'].Value -match 'client-hostname\s+"pstv-bluetooth-audio-bridge";' } |
        ForEach-Object {
            $startMatch = [regex]::Match($_.Groups['body'].Value, 'starts\s+\d+\s+(?<time>\d{4}/\d{2}/\d{2}\s+\d{2}:\d{2}:\d{2});')
            $start = [datetime]::MinValue
            if ($startMatch.Success) {
                [datetime]::TryParseExact($startMatch.Groups['time'].Value, 'yyyy/MM/dd HH:mm:ss',
                    [Globalization.CultureInfo]::InvariantCulture,
                    [Globalization.DateTimeStyles]::AssumeUniversal, [ref]$start) | Out-Null
            }
            [pscustomobject]@{ Address = $_.Groups['ip'].Value; Start = $start }
        } |
        Sort-Object Start -Descending |
        Select-Object -ExpandProperty Address -Unique)
}

function Test-BridgeSshPort {
    param([Parameter(Mandatory = $true)][string]$Address)
    $client = [Net.Sockets.TcpClient]::new()
    try {
        $pending = $client.BeginConnect($Address, 22, $null, $null)
        if (-not $pending.AsyncWaitHandle.WaitOne(750)) { return $false }
        $client.EndConnect($pending)
        $true
    }
    catch { $false }
    finally { $client.Dispose() }
}

function Invoke-BridgeCommand {
    param(
        [Parameter(Mandatory = $true)][string]$Address,
        [Parameter(Mandatory = $true)][string[]]$RemoteCommand
    )

    $plink = Join-Path $PSScriptRoot 'tools\plink.exe'
    $passwordFile = Join-Path $PSScriptRoot 'config\admin-password.txt'
    $hostKeyFile = Join-Path $PSScriptRoot 'config\hostkey.txt'
    if (-not (Test-Path -LiteralPath $plink) -or -not (Test-Path -LiteralPath $passwordFile)) {
        throw 'The bridge management files are missing. Run Install.ps1 again.'
    }

    $arguments = @('-batch', '-ssh', '-P', '22', '-l', 'root', '-pwfile', $passwordFile)
    if (Test-Path -LiteralPath $hostKeyFile) {
        $hostKey = (Get-Content -LiteralPath $hostKeyFile -Raw).Trim()
        if ($hostKey) { $arguments += @('-hostkey', $hostKey) }
    }
    $arguments += $Address
    $arguments += $RemoteCommand
    $output = @(& $plink @arguments 2>&1)
    [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = $output }
}

function Initialize-BridgeHostKey {
    param([Parameter(Mandatory = $true)][string]$Address)

    $plink = Join-Path $PSScriptRoot 'tools\plink.exe'
    $passwordFile = Join-Path $PSScriptRoot 'config\admin-password.txt'
    $hostKeyFile = Join-Path $PSScriptRoot 'config\hostkey.txt'
    if (Test-Path -LiteralPath $hostKeyFile) { return }

    $probe = @(& $plink -batch -ssh -P 22 -l root -pwfile $passwordFile $Address true 2>&1)
    $fingerprint = [regex]::Match(($probe -join "`n"), 'SHA256:[A-Za-z0-9+/=]+')
    if (-not $fingerprint.Success) { return }
    [IO.File]::WriteAllText($hostKeyFile, $fingerprint.Value + "`n", [Text.UTF8Encoding]::new($false))
}

function Find-BridgeAddress {
    foreach ($candidate in @(Get-BridgeDhcpAddresses)) {
        if (-not (Test-BridgeSshPort -Address $candidate)) { continue }
        Initialize-BridgeHostKey -Address $candidate
        if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'config\hostkey.txt'))) { continue }
        try {
            $result = Invoke-BridgeCommand -Address $candidate -RemoteCommand @('true')
            if ($result.ExitCode -eq 0) { return $candidate }
        }
        catch { }
    }
    $null
}
