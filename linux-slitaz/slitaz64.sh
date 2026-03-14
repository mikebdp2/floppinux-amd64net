#!/bin/sh
rm -f "./slitaz64.log"
./kexec    -d -l ./bzImage64 \
    --initrd=./initrd64.lzma \
    --append="root=/dev/null video=-32 autologin lang=en_US kmap=us tz=Europe/London reset_devices" \
    > "./slitaz64.log"   2>&1
  cat "./slitaz64.log"
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
