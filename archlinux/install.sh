#!/bin/bash

# See https://wiki.archlinux.org/index.php/Installation_guide

#-------------------------------------------------------------------------------
# Pre-installation
#-------------------------------------------------------------------------------

# Update the system clock
timedatectl set-ntp true

# Partition the disks
wipefs --all /dev/vda
sgdisk \
	--new 1:0:+512M --typecode 1:ef00 \
	--new 2:34:2047 --typecode 2:ef02 \
	--new 3:0:0 --typecode 3:8300 \
	/dev/vda

# Format the disks
mkfs.fat -F 32 /dev/vda1
mkfs.ext4 -Fb 4096 /dev/vda3

# Mount the file systems
mount /dev/vda3 /mnt/
mkdir --parents /mnt/boot/efi/
mount /dev/vda1 /mnt/boot/efi/


#-------------------------------------------------------------------------------
# Installation
#-------------------------------------------------------------------------------

# Select the mirrors
echo 'Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch' > /etc/pacman.d/mirrorlist

# Install essential packages
pacstrap /mnt/ amd-ucode base cloud-init dosfstools e2fsprogs efibootmgr grub intel-ucode linux linux-firmware lvm2 man-db man-pages mdadm netplan openssh vim

#-------------------------------------------------------------------------------
# Configure the system
#-------------------------------------------------------------------------------

# Fstab
genfstab -U /mnt/ >> /mnt/etc/fstab

# Time zone
arch-chroot /mnt/ ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# Initramfs
arch-chroot /mnt/ sed -i '/^HOOKS=/s/block/block mdadm_udev lvm2/' /etc/mkinitcpio.conf
arch-chroot /mnt/ mkinitcpio -P

# Boot loader
arch-chroot /mnt/ grub-install --target i386-pc /dev/vda
arch-chroot /mnt/ grub-install --target=x86_64-efi --efi-directory=/boot/efi/ --bootloader-id=GRUB
arch-chroot /mnt/ sed -i '/^GRUB_PRELOAD_MODULES=/s/"$/ lvm mdraid09 mdraid1x"/' /etc/default/grub
arch-chroot /mnt/ grub-mkconfig -o /boot/grub/grub.cfg

# Enable services
arch-chroot /mnt/ systemctl enable cloud-init.service cloud-final.service sshd.service

# Symlink vi to vim
ln -s /usr/bin/vim /usr/local/bin/vi
