# Quick Start

## 1. Prepare the PSTV

The PSTV must already be homebrew-enabled and able to load taiHEN kernel plugins. Install VitaBtFix 1.1 and reboot before pairing the bridge. Follow [VITA_SETUP.md](VITA_SETUP.md).

VitaBtFix is required because the stock PSTV Bluetooth stack advances A2DP RTP timestamps incorrectly. Without the plugin, pairing can succeed while audio remains silent or unstable.

## 2. Install VMware Workstation Pro

Install VMware Workstation Pro 17.5.2 or newer. Broadcom's current download procedure requires a free Basic account:

- [Official download instructions](https://knowledge.broadcom.com/external/article/368734/download-desktop-hypervisor-workstation.html)
- [Official installation instructions](https://knowledge.broadcom.com/external/article/387947/installing-vmware-workstation-pro.html)

Reboot Windows if the VMware installer requests it. The bridge needs VMware's USB Arbitration Service and `vmrun.exe`.

## 3. Download and verify the bridge

Download both files from the latest GitHub release:

- `PSTV-Bluetooth-Audio-Bridge-vX.Y.Z.zip`
- `SHA256SUMS.txt`

From PowerShell in the download folder:

```powershell
Get-FileHash -Algorithm SHA256 .\PSTV-Bluetooth-Audio-Bridge-vX.Y.Z.zip
Get-Content .\SHA256SUMS.txt
```

The two hashes must match. Extract the complete archive to a non-system drive. Do not run the installer from inside the ZIP file.

## 4. Run setup

Right-click `Install.ps1`, select **Run with PowerShell**, and approve elevation.

Setup will:

1. Find compatible Windows Bluetooth radios.
2. Ask which radio to dedicate if more than one is present.
3. Generate a unique 256-bit management credential under `config\`; setup uses it automatically.
4. Configure stable USB 2.0 passthrough in the bundled VM.
5. Disable only disconnected Wi-Fi adapters, which prevents background 2.4 GHz scans. Active Wi-Fi is left alone unless setup is run with `-DisableActiveWiFi`.
6. Register the bridge to start for the current Windows user at logon.
7. Boot and securely provision the appliance.
8. Wait for PSTV pairing.

No password, Bluetooth pairing key, PSTV MAC address, or IP address is requested from you.

## 5. Pair the PSTV

When setup displays the pairing prompt:

1. On the PSTV, open **Settings**.
2. Select **Devices → Bluetooth Devices**.
3. Select **PLT Focus**.
4. Accept the pairing request if shown.

Setup detects the paired console automatically. The unique Bluetooth link key is created between that PSTV and that installed VM, then retained inside the appliance for future reconnects.

## 6. Play audio

Start a game or move through a menu that produces sound. The audio goes to the Windows playback device that VMware is using. For the most predictable result, select the desired Windows default output before the bridge starts.

If you change the Windows default output and VMware does not follow it, run:

```powershell
.\Stop-Bridge.ps1
.\Start-Bridge.ps1
```

## Important behavior

- Windows temporarily loses access to the dedicated Bluetooth radio while the VM is running. This is expected.
- Do not dedicate the only adapter used by a Bluetooth keyboard or mouse. Use a separate USB Bluetooth dongle for the bridge.
- The first boot can take up to three minutes. Later boots are much faster.
- A2DP has inherent codec and radio latency. The bridge defaults to a low-latency 60/20 ms playback profile. Run `Set-LatencyProfile.ps1 -Profile UltraLow` for 30/10 ms guest buffering, or `-Profile Stable` to trade more delay for additional dropout tolerance.
- USB 3 devices/cables and 2.4 GHz Wi-Fi near the Bluetooth antenna can create severe interference.

## Check health

```powershell
.\Status.ps1
```

A healthy running bridge reports an adapter, started services, the paired/connected PSTV, and a ready PCM when the PSTV is actively producing audio.
