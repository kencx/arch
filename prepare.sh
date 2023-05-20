#!/bin/bash

set -euo pipefail

# check for dependencies
DEPENDENCIES=(btrfs sgdisk mkfs.fat mkfs.btrfs pacstrap pacman genfstab arch-chroot)
for i in "${DEPENDENCIES[@]}"; do
    if ! which "$i" >/dev/null; then
        echo -e "$i is required!"
    fi
done

# user input
read -r -p "Choose a disk to format: " TARGET_DEVICE
NVME=
if [[ $TARGET_DEVICE =~ ^/dev/nvme.* ]]; then
    NVME=true
fi

DEFAULT_SUBVOLS=(home var tmp .snapshots)
read -r -e -p "Enter btrfs subvolumes names (space-separated) to create (default: ${DEFAULT_SUBVOLS[*]}): " -i "${DEFAULT_SUBVOLS[*]}" -a SUBVOLUMES

DEFAULT_ROOT_MOUNT=/mnt
read -r -e -p "Enter mount point: " -i "${DEFAULT_ROOT_MOUNT}" ROOT_MOUNT

BOOT_MOUNT="${ROOT_MOUNT}/boot"
MOUNT_OPTS="rw,noatime,compress-force=zstd,ssd,nodiscard,space_cache=v2"

# redirect output
LOG_PATH="./arch_prepare.log"
exec &> >(tee -a "${LOG_PATH}")

# partition drive
echo "Partitioning ${TARGET_DEVICE}"
sgdisk -o -n 1:0:+500M -t 1:EF00 -n 2:0:0 -t 2:8300 "${TARGET_DEVICE}"

if [[ $NVME ]]; then
    PARTITION_1="${TARGET_DEVICE}p1"
    PARTITION_2="${TARGET_DEVICE}p2"
else
    PARTITION_1="${TARGET_DEVICE}1"
    PARTITION_2="${TARGET_DEVICE}2"
fi

mkfs.fat -F32 "${PARTITION_1}"
mkfs.btrfs "${PARTITION_2}"
mount -v "${PARTITION_2}" "${ROOT_MOUNT}"

# btrfs subvolumes
echo "Creating btrfs root subvolume"
btrfs subvolume create "${ROOT_MOUNT}/@"

echo "Creating btrfs subvolumes ${SUBVOLUMES[*]}"
for i in "${SUBVOLUMES[@]}"; do
    btrfs subvolume create "${ROOT_MOUNT}/@${i}"
done

umount -v "${ROOT_MOUNT}"

# mount btrfs subvolumes
echo "Mounting btrfs subvolumes"
mount -v -o "$MOUNT_OPTS,subvol=@" "${PARTITION_2}" "${ROOT_MOUNT}"
for i in "${SUBVOLUMES[@]}"; do
    mkdir -pv "${ROOT_MOUNT}/${i}"
    mount -v -o "${MOUNT_OPTS},subvol=@${i}" "${PARTITION_2}" "${ROOT_MOUNT}/${i}"
done

# temp fix to change subvolume /var to /var/log
umount -v "${ROOT_MOUNT}/var"
mkdir -pv "${ROOT_MOUNT}/var/log"
mount -v -o "${MOUNT_OPTS},subvol=@var" "${PARTITION_2}" "${ROOT_MOUNT}/var/log"

# mount boot partition
echo "Mounting boot partition"
mkdir -pv "${BOOT_MOUNT}"
mount -v "${PARTITION_1}" "${BOOT_MOUNT}"

# install
echo "Installing base system"
pacman --no-confirm -Sy archlinux-keyring
pacstrap -K "${ROOT_MOUNT}" base base-devel linux linux-firmware sudo vim grub efibootmgr iwd

echo "Generating fstab"
genfstab -U "${ROOT_MOUNT}" >>"${ROOT_MOUNT}/etc/fstab"

echo "Chroot-ing into ${ROOT_MOUNT}"
# arch-chroot "${ROOT_MOUNT}" /bin/bash
cp ./post-install.sh "${ROOT_MOUNT}/root/post-install.sh"
arch-chroot "${ROOT_MOUNT}" /root/post-install.sh
