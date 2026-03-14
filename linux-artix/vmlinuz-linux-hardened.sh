#!/bin/sh
rm -f "./vmlinuz-linux-hardened.log"
./kexec    -d -l ./vmlinuz-linux-hardened \
    --initrd=./rootfs-wirtl.cpio.lzma \
    --append="$(cat /proc/cmdline) reset_devices" \
    > "./vmlinuz-linux-hardened.log"   2>&1
  cat "./vmlinuz-linux-hardened.log"
sleep 1
echo "5..."
sleep 1
echo "4..."
sleep 1
echo "3..."
sleep 1
echo "2..."
sleep 1
echo "1..."
sleep 1
./kexec -d -e
#
