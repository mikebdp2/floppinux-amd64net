#!/bin/sh
rm -f ./floppinux.img
dd if=/dev/zero of=./floppinux.img bs=1k count=2880
mkdosfs -n FLOPPINUX ./floppinux.img
syslinux --install ./floppinux.img
sudo mount -o loop ./floppinux.img /mnt
rm -f ./bzImage
cp ./linux/arch/x86_64/boot/bzImage ./bzImage
sudo cp ./bzImage /mnt
sudo cp ./rootfs.cpio.lzma /mnt/rfscpiol.zma
sudo cp ./syslinux.cfg /mnt
df -B 1
sudo umount /mnt