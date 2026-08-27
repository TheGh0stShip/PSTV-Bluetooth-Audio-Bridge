# PSTV Bluetooth Audio Bridge

Route PlayStation TV system and game audio to Windows over Bluetooth—without an analog capture cable.

The bridge is a small Alpine Linux appliance for VMware Workstation. It appears to the PSTV as a `PLT Focus` headset, receives SBC/A2DP audio, and plays it through the Windows default output.

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
- Reconnects the paired PSTV automatically after either the console or appliance restarts.
- Installs per-user Windows logon autostart.
- Routes audio to the Windows default output through VMware.
- Leaves every Windows Wi-Fi adapter enabled and unchanged.
- Includes the official VitaBtFix 1.1 plugin and a backed-up FTP installer helper.

## Requirements

| Requirement | Details |
| --- | --- |
| PlayStation TV | Homebrew-enabled and able to load VitaBtFix 1.1. |
| Windows PC | Windows 10 or 11 on x86-64. |
| VMware | [Workstation Pro 17.5.2 or newer](https://knowledge.broadcom.com/external/article/368667/download-and-license-vmware-desktop-hype.html). |
| Bluetooth | A Linux-supported built-in USB-attached radio or external USB dongle. A dedicated dongle is recommended. |
| Network | Ethernet, 5 GHz Wi-Fi, or 6 GHz Wi-Fi is preferred. Wi-Fi remains enabled during setup and use. |

While the bridge runs, Windows cannot use Bluetooth devices attached through the dedicated radio. The Wi-Fi portion of an internal combo adapter remains available.

Tested end-to-end with an Intel `8087:0026` Bluetooth controller, VMware USB 2.0 passthrough, PSTV firmware 3.65, VitaBtFix 1.1, Alpine 3.24, and BlueALSA 4.3.1.

## Quick start

1. Download the latest `PSTV-Bluetooth-Audio-Bridge-v*.zip` from [Releases](https://github.com/TheGh0stShip/PSTV-Bluetooth-Audio-Bridge/releases/latest).
2. Verify the archive using the adjacent `SHA256SUMS.txt`.
3. Extract the entire folder to a non-system drive with at least 2 GB free.
4. Install VitaBtFix using [the PSTV preparation guide](docs/VITA_SETUP.md).
5. Double-click `SETUP.cmd` and approve the administrator prompt.
6. On the PSTV, open **Settings → Devices → Bluetooth Devices**, then select **PLT Focus**.
7. Play anything. Audio follows the Windows default playback device.

See [Quick Start](docs/QUICKSTART.md) for the complete walkthrough.

## Everyday use

The bridge starts 15 seconds after Windows logon. A paired PSTV normally reconnects within 30 seconds after reboot.

| Command | Purpose |
| --- | --- |
| `Status.ps1` | Show connection and service health. |
| `Status.ps1 -Diagnostics` | Collect detailed diagnostics. |
| `Pair-PSTV.ps1` | Reopen pairing mode. |
| `Set-LatencyProfile.ps1` | Select UltraLow, LowLatency, or Stable buffering. |
| `Stop-Bridge.ps1` | Stop the VM and return the Bluetooth radio to Windows. |
| `Start-Bridge.ps1` | Start the bridge again. |
| `Uninstall.ps1` | Remove autostart and stop the appliance. |

## Why the custom BlueALSA build?

- **Problem:** the PSTV negotiated SBC bitpool 51, which consumed too much reliable airtime in the tested VMware Bluetooth path.
- **Change:** the appliance keeps BlueALSA 4.3.1's normal source capability but caps its A2DP sink capability at bitpool 20.
- **Result:** with VitaBtFix, USB autosuspend suppression, USB 2.0 passthrough, and disabled sniff mode, the test stream delivered 2,783 consecutive packets with zero missing packets.

Details are in [Architecture](docs/ARCHITECTURE.md).

## Build it yourself

The release VM is reproducible from the included Alpine rootfs overlay and full corresponding BlueALSA source. See [Building](docs/BUILDING.md).

## Support and safety

Read [Troubleshooting](docs/TROUBLESHOOTING.md) before filing an issue. VitaBtFix is an experimental kernel plugin; hold **L** during PSTV boot to skip kernel plugins if the console has trouble starting.

This project is independent community software and is not affiliated with or endorsed by Sony Interactive Entertainment, Broadcom, VMware, Alpine Linux, or the BlueALSA project. PlayStation and PS Vita are trademarks of their respective owners.

## License

Original project code is MIT licensed. Vendored BlueALSA source remains GPL-3.0-or-later, and VitaBtFix remains MIT licensed by its author. See [Third-Party Notices](THIRD_PARTY_NOTICES.md).
