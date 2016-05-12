#!/bin/bash

while [ x$username = “x” ]; do

read -p “Create the user account:” username

if id -u $username >/dev/null 2>&1; then

echo “That user already exists.”

username=“”

fi

read -p “Create the user $username? [y/n]:” confirm

if [ “$confirm” = “y” ]; then

useradd -mG wheel -s /bin/bash $username

if [ “$confirm” = “n” ]; then

echo “User creation cancelled”

fi

while [ x$passphrase = “x” ]

read -p “Set the root password:” $passphrase

usermod -p $passphrase root

#add the wheel group to /etc/sudoers
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

#bootctl install
bootctl install

#echo disk UUID for /dev/sda2 into /boot/loader/entries/arch.conf
blkid /dev/sda2 | awk -F\" ‘{print $2}’ > /boot/loader/entries/arch.conf

#finish creating /boot/loader/entries/arch.conf and add correct hooks to mkinitcpio.conf
nano /boot/loader/entries/arch.conf
sed s/‘HOOKS=”base udev autodetect modconf block filesystems keyboard fsck”’/‘HOOKS=”base udev autodetect modconf block keymap encrypt lvm2 resume filesystems keyboard fsck”’/g

#update systemd-boot and mkinitcpio.conf
bootctl update
mkinitcpio -p linux

#set the locale, timezone, and keymap
echo ‘en_US.UTF-8 UTF-8’ > /etc/locale.gen
locale.gen
echo ‘LANG=en_US.UTF-8’ > /etc/locale.conf

ln -s /usr/share/zoneinfo/America/Detroit
hwclock --systohc --utc

echo ‘KEYMAP=us’ > /etc/vconsole.conf

#install some packages
pacman -S intel-ucode networkmanager

#enable networkmanager and set hostname
systemctl enable NetworkManager
echo "archworkstation" > /etc/hostname
nano /etc/hosts

#install multilib and yaourt AUR access
sed -i 's/#Color/Color/' /etc/pacman.conf
sed -i 's/#\[multilib\]/\[multilib\]\nInclude = \/etc\/pacman.d\/mirrorlist/' /etc/pacman.conf

echo ‘[archlinuxfr]
SigLevel = Never
Server = http://repo.archlinux.fr/$arch’ >> /etc/pacman.conf

pacman -S yaourt aurvote
