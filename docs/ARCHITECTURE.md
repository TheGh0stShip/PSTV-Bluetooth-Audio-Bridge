# Architecture

## Data path

1. The PSTV sees the passed-through Bluetooth controller as a classic A2DP sink named `PLT Focus`.
2. VitaBtFix corrects the PSTV's RTP timestamp increment from the incompatible value to 512 samples per packet.
3. BlueZ receives the A2DP transport inside an Alpine Linux VM.
4. A source-compatible BlueALSA 4.3.1 daemon decodes SBC into 48 kHz, 16-bit stereo PCM.
5. `bluealsa-aplay` sends PCM to the VM's default ALSA card.
6. VMware's virtual HDA device plays through the Windows host audio system.

## Why a VM?

Windows' normal Bluetooth stack does not expose a convenient, universal A2DP-sink playback device for this PSTV use case. Passing the physical radio to a tiny Linux guest provides a mature BlueZ/BlueALSA receiver while VMware maps its ordinary sound card into Windows.

The appliance uses DHCP, and the host helper discovers its lease by the appliance hostname. No host-only subnet or fixed guest IP is assumed.

## Stability changes

The working configuration combines several independent fixes:

- **VitaBtFix 1.1:** repairs RTP timestamp progression at the source.
- **SBC bitpool 20 sink cap:** reduces radio airtime and packet loss. Only `a2dp_sbc_sink` is changed; the source capability remains upstream default.
- **USB 2.0/EHCI passthrough:** avoids the stalls observed with VMware xHCI.
- **No USB autosuspend:** keeps the physical Bluetooth controller awake.
- **No Bluetooth sniff mode:** allows role switch but prevents the audio ACL link from entering a low-duty-cycle power mode.
- **High host VM priority:** reduces scheduling jitter.
- **60 ms/20 ms low-latency ALSA buffer/period:** keeps exactly three periods, BlueALSA's documented reliability minimum, while removing most bridge-side queuing. An optional 200/50 ms stable profile absorbs greater host scheduling variance.
- **Wi-Fi coexistence control:** disconnected Wi-Fi radios are disabled by setup to prevent background 2.4 GHz scanning.

The final development capture after these changes contained 2,783 consecutive audio packets, zero missing RTP packets, no interval above 100 ms, and a 69 ms maximum interval.

## Security model

- The release image contains no private key, password, Bluetooth link key, paired device, host SSH key, PSTV address, or user path.
- Setup generates a random 256-bit management credential locally and stores it only under the installed `config\` directory.
- The credential is passed through VMware `guestinfo` on first boot, used to initialize the guest, and cleared from the running guestinfo value.
- The appliance generates unique SSH host keys on first boot.
- The bundled PuTTY command-line client uses the credential from its file without exposing it on the command line and pins the generated SSH host-key fingerprint.
- Pairing is classic Bluetooth Just Works because that is what the PSTV supports. Pair only in a trusted physical environment, then allow discoverability to time out.

## Reproducibility and licensing

The complete modified BlueALSA 4.3.1 corresponding source is under `third_party/bluez-alsa`, including its GPL-3.0-or-later license. The single functional change is also supplied as `patches/bluez-alsa-v4.3.1-pstv-bitpool20.patch`.

The prebuilt appliance is derived from Alpine Linux packages and includes their package metadata. VitaBtFix binaries are redistributed unchanged under the upstream MIT license.
