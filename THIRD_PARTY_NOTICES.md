# Third-Party Notices

## BlueALSA

- Project: https://github.com/arkq/bluez-alsa
- Version: v4.3.1, upstream commit `f115694`
- License: GPL-3.0-or-later
- Corresponding modified source: `third_party/bluez-alsa/`
- Modification: the A2DP sink maximum SBC bitpool is capped at 20. See `patches/bluez-alsa-v4.3.1-pstv-bitpool20.patch`.

BlueALSA's original license text is retained at `third_party/bluez-alsa/LICENSE`.

## VitaBtFix

- Author: gabew100
- Project: https://github.com/gabew100/VitaBtFix
- Release: v1.1
- License: MIT
- Included unchanged files:
  - `vita/vitabtfix.skprx` — SHA-256 `c22e12dac6d870cddfabac290a693403cd930f7885ff4d18825db206f185d1e8`
  - `vita/vitabtfix-3.60.skprx` — SHA-256 `bd101e3afda630f39af898a8333357189057363b82a55393162d1a404317935d`

Copyright and permission terms are available in the upstream [MIT license](https://github.com/gabew100/VitaBtFix/blob/main/LICENSE).

## Alpine Linux and packages

The appliance is built on Alpine Linux 3.24 and includes unmodified Alpine packages. Package copyright and license metadata remain installed in the image. Alpine license information: https://www.alpinelinux.org/about/

## VMware Workstation

VMware software is not redistributed by this project. Users obtain VMware Workstation Pro directly from Broadcom under Broadcom's terms.

## PuTTY

- Project: https://www.chiark.greenend.org.uk/~sgtatham/putty/
- Version: 0.85
- Included file: `tools/plink.exe` (official 64-bit Windows build)
- SHA-256: `969f36879d5716aa1a9811f43a6a6510e8f08372dbeb9695b810b9c776f39c75`
- License: MIT

The official license text is included as `tools/PUTTY-LICENSE.html`. Plink is used only for automatic, host-key-pinned management of the local NAT appliance.
