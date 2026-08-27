# Troubleshooting

Start with:

```powershell
.\Status.ps1
.\Status.ps1 -Diagnostics
```

Attach the diagnostic output and `logs\host.log` when opening an issue. Never attach `config\admin-password.txt`.

## PSTV pairs, but there is no sound

1. Verify `ux0:data/vitabtfix/log.txt` contains a successful `-> +512 ok` patch line.
2. Confirm VitaBtFix is under `*KERNEL` in `ur0:tai/config.txt`, then reboot the PSTV.
3. Produce a known UI/game sound. The PCM can correctly show idle when the PSTV is silent.
4. If the PSTV displays its mute state unexpectedly, reboot the PSTV once. Its Bluetooth audio state can wedge after repeated failed reconnects.
5. Run `Stop-Bridge.ps1`, wait five seconds, then run `Start-Bridge.ps1`.

Do not force a live SBC codec change. The appliance advertises its tested low-bandwidth capability before connection; changing codec parameters midstream can disconnect and wedge the PSTV Bluetooth controller.

## Audio is choppy, delayed, or arrives in bursts

The common cause is 2.4 GHz packet loss rather than Windows audio buffering.

- Use Ethernet for the PC where possible.
- Keep Wi-Fi enabled if it is your network connection. When possible, connect it to a 5 GHz or 6 GHz band; setup never disables or reconfigures it.
- If the PC must use Wi-Fi, use a 5 GHz or 6 GHz network.
- Place the PSTV and Bluetooth antenna within a few meters with clear line of sight.
- Move USB 3 hubs, drives, and unshielded USB 3 cables away from the Bluetooth antenna.
- Prefer a dedicated USB Bluetooth adapter on a short USB 2 extension cable.
- Verify the VMX still contains `ehci.present = "TRUE"` and `usb_xhci.present = "FALSE"`.

The appliance deliberately uses USB 2.0 passthrough. Switching to VMware xHCI/USB 3 recreated long stalls during development.

## `PLT Focus` does not appear

1. Run `Pair-PSTV.ps1` again.
2. Check `Status.ps1` reports `adapter=yes`.
3. Ensure VMware USB Arbitration Service is running:

```powershell
Get-Service VMUSBArbService
```

4. Confirm no other VM owns the Bluetooth radio.
5. Stop the bridge and unplug/reinsert a dedicated USB Bluetooth adapter, then start it again.
6. Some vendor-specific radios lack Linux firmware support. Try a common Intel, Broadcom, Realtek, or CSR USB adapter and include its VID/PID in an issue report.

## Windows Bluetooth disappeared

Expected: VMware gives the complete physical radio to the appliance. Stop the bridge to return it:

```powershell
.\Stop-Bridge.ps1
```

If Windows Bluetooth peripherals must remain connected, dedicate a second USB Bluetooth adapter to the bridge.

## Audio goes to the wrong Windows device

VMware normally opens the Windows default playback device when the VM starts. Select the desired Windows default output, then restart the bridge:

```powershell
.\Stop-Bridge.ps1
.\Start-Bridge.ps1
```

## Pairing worked before but no longer reconnects

1. Reboot the PSTV.
2. Run `Pair-PSTV.ps1` and select `PLT Focus` again.
3. If needed, forget `PLT Focus` on the PSTV and re-pair.

The appliance trusts paired devices and attempts reconnects with a 30-second backoff. It also prevents Bluetooth sniff mode and USB autosuspend after every reconnect.

## Installer cannot provision the guest

- Confirm VMware NAT networking is enabled.
- Do not copy a previously installed `config\` directory into a fresh release.
- Make sure endpoint security is not blocking `vmrun.exe`, `vmware-vmx.exe`, or the bundled `tools\plink.exe`.
- Delete only the generated VM runtime files (`*.lck`, `*.vmem`, `*.vmss`) while the VM is stopped; never delete the VMDK.

## Restore Wi-Fi or remove the bridge

Run:

```powershell
.\Uninstall.ps1
```

It removes autostart and stops the VM. Add `-RemoveConfiguration` only if you also want to remove generated credentials and pairing-management configuration. Current releases do not disable or reconfigure Wi-Fi.
