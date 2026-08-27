# PSTV Bluetooth Audio Bridge

Route PlayStation TV system and game audio to the current Windows playback device over Bluetooth—without an analog capture cable.

This project packages the working solution as a small Alpine Linux appliance for VMware Workstation. The VM presents itself to the PSTV as a `PLT Focus` Bluetooth headset, receives SBC/A2DP audio, and plays it through VMware's virtual sound card into Windows.

```mermaid
flowchart LR
    A[PlayStation TV] -->|Bluetooth A2DP / SBC| B[USB Bluetooth radio]
    B --> C[Alpine appliance]
    C -->|Patched BlueALSA| D[VMware virtual audio]
    D --> E[Windows default output]
```

## What the installer handles

- Detects the PC's USB Bluetooth radio and dedicates it to the appliance.
- Generates a unique 256-bit management credential automatically; no bundled password, SSH key, Bluetooth link key, PSTV MAC, or fixed guest IP is used.
- Configures stable VMware USB 2.0 passthrough.
- Starts a clean, preconfigured Alpine VM and provisions it over DHCP.
- Advertises the receiver as `PLT Focus` and detects PSTV pairing automatically.
- Installs per-user Windows logon autostart.
- Routes audio to the Windows default output through VMware.
- Includes the official VitaBtFix 1.1 plugin and a backed-up FTP installer helper.

## Requirements

- A homebrew-enabled PlayStation TV.
- Windows 10 or Windows 11 on an x86-64 PC.
- [VMware Workstation Pro 17.5.2 or newer](https://knowledge.broadcom.com/external/article/368667/download-and-license-vmware-desktop-hype.html). Broadcom currently provides supported versions free for personal, educational, and commercial use.
- A USB-attached Bluetooth radio supported by Linux. A dedicated USB adapter is recommended; an internal Intel combo radio also works but becomes unavailable to Windows while the bridge runs.
- VitaBtFix 1.1 installed on the PSTV.
- Ethernet or 5 GHz Wi-Fi is strongly recommended. The PSTV and Bluetooth both use 2.4 GHz, where contention can cause stalls.

Tested end-to-end with an Intel `8087:0026` Bluetooth controller, VMware USB 2.0 passthrough, PSTV firmware 3.65, VitaBtFix 1.1, Alpine 3.24, and BlueALSA 4.3.1.

## Quick start

1. Download the latest `PSTV-Bluetooth-Audio-Bridge-v*.zip` from [Releases](https://github.com/TheGh0stShip/PSTV-Bluetooth-Audio-Bridge/releases/latest).
2. Verify the archive using the adjacent `SHA256SUMS.txt`.
3. Extract the entire folder to a non-system drive with at least 2 GB free.
4. Install VitaBtFix using [the PSTV preparation guide](docs/VITA_SETUP.md).
5. Right-click `Install.ps1` and choose **Run with PowerShell**. Approve the administrator prompt.
6. On the PSTV, open **Settings → Devices → Bluetooth Devices**, then select **PLT Focus**.
7. Play anything. Audio follows the Windows default playback device.

See [Quick Start](docs/QUICKSTART.md) for the complete walkthrough.

## Everyday use

The bridge starts automatically 15 seconds after Windows logon. The Bluetooth adapter is owned by the VM while it runs, so Windows Bluetooth devices using that same radio will be unavailable.

- `Status.ps1` — show connection and service health.
- `Status.ps1 -Diagnostics` — collect detailed live diagnostics.
- `Pair-PSTV.ps1` — reopen pairing mode.
- `Set-LatencyProfile.ps1` — switch between low-latency and extra-stable playback buffering.
- `Stop-Bridge.ps1` — stop the VM and return the Bluetooth radio to Windows.
- `Start-Bridge.ps1` — start it again.
- `Uninstall.ps1` — remove autostart, stop the appliance, and restore Wi-Fi adapters changed by setup.

## Why the custom BlueALSA build?

The PSTV originally negotiated SBC bitpool 51, which consumed too much reliable airtime in the tested VMware Bluetooth path. This appliance keeps BlueALSA 4.3.1's normal source capability intact but caps only the A2DP sink capability at bitpool 20. Combined with VitaBtFix's RTP timestamp correction, USB autosuspend suppression, USB 2.0 passthrough, and disabled sniff mode, the tested stream delivered 2,783 consecutive packets with zero missing packets.

Details are in [Architecture](docs/ARCHITECTURE.md).

## Build it yourself

The release VM is reproducible from the included Alpine rootfs overlay and full corresponding BlueALSA source. See [Building](docs/BUILDING.md).

## Support and safety

Read [Troubleshooting](docs/TROUBLESHOOTING.md) before filing an issue. VitaBtFix is an experimental kernel plugin; hold **L** during PSTV boot to skip kernel plugins if the console has trouble starting.

This project is independent community software and is not affiliated with or endorsed by Sony Interactive Entertainment, Broadcom, VMware, Alpine Linux, or the BlueALSA project. PlayStation and PS Vita are trademarks of their respective owners.

## License

Original project code is MIT licensed. Vendored BlueALSA source remains GPL-3.0-or-later, and VitaBtFix remains MIT licensed by its author. See [Third-Party Notices](THIRD_PARTY_NOTICES.md).
