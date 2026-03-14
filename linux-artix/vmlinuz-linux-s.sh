#!/bin/sh
rm -f "./vmlinuz-linux-s.log"
./kexec -s -d -l ./vmlinuz-linux \
    --initrd=./rootfs-wirtl.cpio.lzma \
    --append="$(cat /proc/cmdline) reset_devices" \
    > "./vmlinuz-linux-s.log" 2>&1
  cat "./vmlinuz-linux-s.log"
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
