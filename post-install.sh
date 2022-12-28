#!/bin/bash

set -euo pipefail

BOOT_DIR="/boot"
TIMEZONE="Asia/Singapore"
LOCALE="en_US.UTF-8"
USERNAME="kenc"

# timezone
ln -s /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
hwclock --systohc

# localization
sed -i "/^#.*${LOCALE}/s/^# //g" /etc/locale.gen
locale-gen

echo "LANG=${LOCALE}" > /etc/locale.conf
echo "arch" > /etc/hostname

# Create non-root user
passwd
useradd -m $USERNAME
passwd kenc
usermod -aG wheel $USERNAME

# grub
grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=${BOOT_DIR} --removable
grub-mkconfig -o /${BOOT_DIR}/grub/grub.cfg
