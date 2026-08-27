#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
alpine_version=3.24.1
alpine_arch=x86_64
cache_dir="$repo_root/.cache"
work_dir="$repo_root/.work/appliance"
mount_dir="$work_dir/root"
raw_disk="$work_dir/PSTV-Bluetooth-Audio-Bridge.raw"
output_dir="$repo_root/out/vm"
output_vmdk="$output_dir/PSTV-Bluetooth-Audio-Bridge.vmdk"
minirootfs="alpine-minirootfs-${alpine_version}-${alpine_arch}.tar.gz"
download_url="https://dl-cdn.alpinelinux.org/alpine/v3.24/releases/x86_64/$minirootfs"
loop_device=

case "$work_dir" in
	"$repo_root"/.work/appliance) ;;
	*) echo "Refusing unexpected work directory: $work_dir" >&2; exit 1 ;;
esac

for command in curl sha256sum tar truncate parted losetup mkfs.ext4 mount chroot extlinux qemu-img; do
	command -v "$command" >/dev/null || { echo "Missing build dependency: $command" >&2; exit 1; }
done

cleanup() {
	set +e
	for path in "$mount_dir/run" "$mount_dir/sys" "$mount_dir/proc" "$mount_dir/dev" "$mount_dir"; do
		mountpoint -q "$path" && umount -R "$path"
	done
	if [ -n "$loop_device" ] && losetup "$loop_device" >/dev/null 2>&1; then
		losetup -d "$loop_device"
	fi
}
trap cleanup EXIT

mkdir -p "$cache_dir" "$output_dir"
if [ ! -f "$cache_dir/$minirootfs" ]; then
	curl --fail --location --output "$cache_dir/$minirootfs" "$download_url"
fi
curl --fail --location --output "$cache_dir/$minirootfs.sha256" "$download_url.sha256"
(
	cd "$cache_dir"
	sha256sum --check "$minirootfs.sha256"
)

rm -rf "$work_dir"
mkdir -p "$mount_dir"
truncate -s 2G "$raw_disk"
parted -s "$raw_disk" mklabel msdos
parted -s "$raw_disk" mkpart primary ext4 1MiB 100%
parted -s "$raw_disk" set 1 boot on

loop_device="$(losetup --find --show --partscan "$raw_disk")"
partition="${loop_device}p1"
for _ in $(seq 1 20); do
	[ -b "$partition" ] && break
	sleep 0.25
done
[ -b "$partition" ]

mkfs.ext4 -F -L pstv-bridge "$partition"
mount "$partition" "$mount_dir"
tar -xzf "$cache_dir/$minirootfs" -C "$mount_dir"
cp -a "$repo_root/appliance/rootfs/." "$mount_dir/"
cp -a "$repo_root/third_party/bluez-alsa" "$mount_dir/tmp/bluez-alsa"
cp -L /etc/resolv.conf "$mount_dir/etc/resolv.conf"

for path in dev proc sys run; do
	mount --rbind "/$path" "$mount_dir/$path"
	mount --make-rslave "$mount_dir/$path"
done

chroot "$mount_dir" /bin/sh <<'CHROOT'
set -eux

cat > /etc/apk/repositories <<'EOF'
https://dl-cdn.alpinelinux.org/alpine/v3.24/main
https://dl-cdn.alpinelinux.org/alpine/v3.24/community
EOF

apk update
apk add alpine-base linux-lts linux-firmware-intel bluez bluez-deprecated \
	bluez-alsa=4.3.1-r0 bluez-alsa-utils=4.3.1-r0 alsa-utils dbus \
	open-vm-tools openssh e2fsprogs util-linux tzdata
apk add --virtual .pstv-build-deps build-base autoconf automake libtool pkgconf \
	linux-headers alsa-lib-dev bluez-dev dbus-dev glib-dev sbc-dev

cd /tmp/bluez-alsa
# The repository is commonly checked out on Windows with CRLF conversion.
# Normalize build-system and source text inside the disposable image only.
find . -type f \( -name '*.c' -o -name '*.h' -o -name '*.am' -o -name '*.ac' \
	-o -name '*.in' -o -name '*.sh' -o -name '*.py' -o -name '*.conf' \
	-o -name '*.md' \) -exec sed -i 's/\r$//' {} +
autoreconf -fi
mkdir output
cd output
../configure \
	--enable-a2dp-sink \
	--disable-aac \
	--disable-aptx \
	--disable-aptx-hd \
	--disable-faststream \
	--disable-lc3plus \
	--disable-ldac \
	--disable-midi \
	--disable-mp3lame \
	--disable-mpg123 \
	--disable-msbc \
	--disable-opus \
	--disable-ofono \
	--disable-systemd \
	--disable-upower \
	--disable-aplay \
	--disable-rfcomm \
	--disable-a2dpconf \
	--disable-hcitop \
	--disable-manpages \
	--disable-test
make -j2
install -m 0755 src/bluealsa /usr/local/sbin/bluealsa-pstv
strip /usr/local/sbin/bluealsa-pstv
/usr/local/sbin/bluealsa-pstv --version | grep -F 'v4.3.1'
apk del .pstv-build-deps
rm -rf /tmp/bluez-alsa

echo pstv-bluetooth-audio-bridge > /etc/hostname
cat > /etc/hosts <<'EOF'
127.0.0.1 localhost localhost.localdomain
127.0.1.1 pstv-bluetooth-audio-bridge
EOF
cat > /etc/network/interfaces <<'EOF'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF
cat > /etc/fstab <<'EOF'
LABEL=pstv-bridge / ext4 defaults,noatime 0 1
EOF
cat > /etc/machine-info <<'EOF'
PRETTY_HOSTNAME=PLT Focus
EOF
cat > /etc/modules <<'EOF'
btusb
snd_hda_intel
e1000
EOF
cat > /etc/asound.conf <<'EOF'
pcm.!default {
	type plug
	slave.pcm "hw:0,0"
}
ctl.!default {
	type hw
	card 0
}
EOF

ln -sf /usr/share/zoneinfo/UTC /etc/localtime
echo UTC > /etc/timezone
mkdir -p /var/lib/pstv-bridge /var/lib/bluealsa /usr/var/lib/bluealsa
sed -i 's|^root:[^:]*:|root:*:|' /etc/shadow
cat >> /etc/ssh/sshd_config <<'EOF'
PermitRootLogin yes
PasswordAuthentication yes
KbdInteractiveAuthentication no
EOF
rm -f /etc/ssh/ssh_host_* /etc/machine-id

chmod 755 /etc/init.d/bluealsa /etc/init.d/bluealsa-aplay \
	/etc/init.d/pstv-firstboot /etc/init.d/pstv-bridge \
	/usr/local/sbin/pstv-firstboot /usr/local/sbin/pstv-pairing-mode \
	/usr/local/sbin/pstv-bridge-daemon /usr/local/sbin/pstv-status \
	/usr/local/sbin/pstv-diagnose

for service in modules sysctl hostname bootmisc syslog networking; do
	rc-update add "$service" boot 2>/dev/null || true
done
for service in dbus bluetooth open-vm-tools alsa pstv-firstboot sshd \
	bluealsa bluealsa-aplay pstv-bridge; do
	rc-update add "$service" default
done

rm -rf /var/cache/apk/* /var/log/* /tmp/*
CHROOT

mkdir -p "$mount_dir/boot/syslinux"
extlinux --install "$mount_dir/boot/syslinux"
cat > "$mount_dir/boot/syslinux/syslinux.cfg" <<'EOF'
PROMPT 0
TIMEOUT 10
DEFAULT alpine

LABEL alpine
  LINUX /boot/vmlinuz-lts
  INITRD /boot/initramfs-lts
  APPEND root=LABEL=pstv-bridge modules=sd-mod,ext4 quiet
EOF

mbr_binary="$(find /usr/lib/syslinux -name mbr.bin -print -quit)"
[ -n "$mbr_binary" ]
dd if="$mbr_binary" of="$loop_device" bs=440 count=1 conv=notrunc status=none
sync

cleanup
trap - EXIT
loop_device=

temporary_vmdk="$work_dir/PSTV-Bluetooth-Audio-Bridge.vmdk"
qemu-img convert -p -f raw -O vmdk -o subformat=monolithicSparse "$raw_disk" "$temporary_vmdk"
qemu-img check "$temporary_vmdk"
install -m 0644 "$temporary_vmdk" "$output_vmdk"
install -m 0644 "$repo_root/appliance/PSTV-Bluetooth-Audio-Bridge.vmx" \
	"$output_dir/PSTV-Bluetooth-Audio-Bridge.vmx"
qemu-img check "$output_vmdk"
qemu-img info "$output_vmdk"
echo "Built: $output_dir"
