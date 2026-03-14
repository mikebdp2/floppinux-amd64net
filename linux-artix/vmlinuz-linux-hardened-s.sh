#!/bin/sh
rm -f "./vmlinuz-linux-hardened-s.log"
./kexec -s -d -l ./vmlinuz-linux-hardened \
    --initrd=./rootfs-wirtl.cpio.lzma \
    --append="$(cat /proc/cmdline) reset_devices" \
    > "./vmlinuz-linux-hardened-s.log" 2>&1
  cat "./vmlinuz-linux-hardened-s.log"
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
