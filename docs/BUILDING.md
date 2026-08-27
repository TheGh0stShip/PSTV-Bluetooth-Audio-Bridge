# Building the Appliance

The official release VM is built from the repository, not copied from a live paired installation.

## Build host

- Windows 10/11 x86-64
- WSL 2 with Ubuntu
- At least 6 GB free on a non-system drive

Install build dependencies inside Ubuntu:

```bash
sudo apt update
sudo apt install -y curl coreutils tar util-linux mount parted e2fsprogs \
  syslinux syslinux-common qemu-utils
```

From an elevated Windows PowerShell in the repository:

```powershell
.\build\Build-Appliance.ps1
```

The build performs these steps:

1. Downloads Alpine 3.24.1 minirootfs and verifies its official SHA-256 file.
2. Creates a fresh 2 GB ext4 disk image.
3. Installs only runtime packages plus temporary compiler dependencies.
4. Builds the vendored, corresponding BlueALSA 4.3.1 source.
5. Confirms the patched daemon reports v4.3.1.
6. Removes compilers, build dependencies, package cache, logs, machine identity, SSH host keys, and all Bluetooth state.
7. Installs the rootfs overlay and bootloader.
8. Converts the raw disk to a monolithic sparse VMDK and verifies it with `qemu-img check`.

Output:

```text
out/vm/PSTV-Bluetooth-Audio-Bridge.vmx
out/vm/PSTV-Bluetooth-Audio-Bridge.vmdk
```

## Create a release bundle

```powershell
.\build\New-Release.ps1 -Version 1.1.0
```

The packager rejects VM runtime state, logs, host-key files, and management credentials. It creates a per-file manifest inside the bundle and a SHA-256 file alongside the final ZIP.

## Verify the source delta

The intended BlueALSA change is exactly one line in `src/a2dp-sbc.c`: the A2DP sink's maximum SBC bitpool is capped at 20. Compare the vendored tree with upstream tag `v4.3.1` or apply the patch under `patches/` to a clean upstream checkout.
