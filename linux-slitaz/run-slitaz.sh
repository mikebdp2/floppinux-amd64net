#!/bin/sh
rm -f "./run-slitaz.log"
./kexec -s -d -l ./bzImage64 \
    --initrd=./initrd32.lzma \
    --append="root=/dev/null video=-32 autologin lang=en_US kmap=us tz=Europe/London reset_devices" \
    > "./run-slitaz.log" 2>&1
  cat "./run-slitaz.log"
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
