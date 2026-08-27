# Contributing

Issues and pull requests are welcome, especially hardware compatibility reports.

## Bug reports

Include:

- Windows version.
- VMware Workstation version.
- Bluetooth adapter name and USB VID/PID.
- PSTV firmware version.
- VitaBtFix log status.
- Whether the PC uses Ethernet, 2.4 GHz Wi-Fi, or 5/6 GHz Wi-Fi.
- Output from `Status.ps1 -Diagnostics`.

Remove public IP addresses or other personal information. Never upload `config/admin-password.txt`, VMware `.vmem`/`.vmss` state, or `/var/lib/bluetooth` contents.

## Pull requests

- Keep Windows automation compatible with Windows PowerShell 5.1.
- Keep appliance scripts compatible with BusyBox `sh` unless a dependency change is justified.
- Run the local parser/shell checks described in `docs/BUILDING.md`.
- Do not commit built VMDKs, release ZIPs, credentials, packet captures, pairing databases, or runtime logs.
- Update documentation and the changelog for user-visible behavior.

BlueALSA changes must retain GPL-3.0-or-later notices and include complete corresponding source.
