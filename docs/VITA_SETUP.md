# PSTV Preparation: VitaBtFix 1.1

VitaBtFix by `gabew100` corrects the PSTV/PS Vita A2DP timestamp behavior that otherwise causes silence with this receiver. The plugin is MIT licensed and included unchanged from its official v1.1 release.

## Supported firmware builds

- Firmware 3.63 and newer: `vita\vitabtfix.skprx`
- Firmware 3.60–3.62: `vita\vitabtfix-3.60.skprx` (install it under the filename `vitabtfix.skprx`)

## Assisted VitaShell FTP install

1. Open VitaShell on the PSTV.
2. Press **SELECT** to start its FTP server.
3. Note the PSTV IP shown on screen.
4. From the extracted bridge folder, run:

```powershell
.\Install-VitaBtFix.ps1 -VitaIp 192.168.1.50
```

For firmware 3.60–3.62:

```powershell
.\Install-VitaBtFix.ps1 -VitaIp 192.168.1.50 -Firmware360
```

The helper:

- Downloads `ur0:tai/config.txt` and creates a timestamped local backup.
- Uploads an on-console backup as `ur0:tai/config.txt.pstv-bridge.bak`.
- Uploads the correct plugin as `ur0:tai/vitabtfix.skprx`.
- Inserts the plugin entry immediately below `*KERNEL`.
- Refuses to change anything if the `*KERNEL` section is missing.

Stop VitaShell FTP and reboot the PSTV afterward.

## Manual install

1. Copy the correct build to `ur0:tai/vitabtfix.skprx`.
2. Open `ur0:tai/config.txt`.
3. Add this line directly under `*KERNEL`:

```text
ur0:tai/vitabtfix.skprx
```

4. Save the file and reboot the PSTV.

Do not add the line to `ux0:tai/config.txt` or `tai_old`. The active path should be `ur0:tai/config.txt`.

## Verify the plugin

After reboot, check `ux0:data/vitabtfix/log.txt`. A successful installation contains a timestamp patch line ending in `-> +512 ok` and identifies VitaBtFix 1.1 as ready.

If the PSTV has trouble booting, hold **L** while it boots to skip kernel plugins. Then remove or rename `ur0:tai/vitabtfix.skprx` and remove its config entry.

Upstream source and releases: [gabew100/VitaBtFix](https://github.com/gabew100/VitaBtFix)
