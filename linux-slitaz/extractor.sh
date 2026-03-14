#!/bin/sh
#
# Extract the files out of a Slitaz ISO image
#
sudo mount ./slitaz-rolling-core-5in1.iso /mnt
#
rm -f ./bzImage
rm -f ./bzImage64
cp /mnt/boot/bzImage ./bzImage
cp /mnt/boot/bzImage64 ./bzImage64
#
rm -f ./rootfs1.gz64
rm -f ./rootfs1.gz
rm -f ./rootfs2.gz
rm -f ./rootfs3.gz
rm -f ./rootfs4.gz
rm -f ./rootfs5.gz
cp /mnt/boot/rootfs1.gz64 ./rootfs1.gz64
cp /mnt/boot/rootfs1.gz   ./rootfs1.gz
cp /mnt/boot/rootfs2.gz   ./rootfs2.gz
cp /mnt/boot/rootfs3.gz   ./rootfs3.gz
cp /mnt/boot/rootfs4.gz   ./rootfs4.gz
cp /mnt/boot/rootfs5.gz   ./rootfs5.gz
#
rm -f ./initrd
rm -f ./initrd.lzma
xz --single-stream -cd ./rootfs5.gz   >> ./initrd
xz --single-stream -cd ./rootfs4.gz   >> ./initrd
xz --single-stream -cd ./rootfs3.gz   >> ./initrd
xz --single-stream -cd ./rootfs2.gz   >> ./initrd
xz --single-stream -cd ./rootfs1.gz   >> ./initrd
xz --threads=1 --format=lzma --check=crc32 --lzma1=dict=64MiB,lc=3,lp=0,pb=2,mode=normal,nice=273,mf=bt4,depth=0 < ./initrd > ./initrd.lzma
#
rm -f ./initrd64
rm -f ./initrd64.lzma
xz --single-stream -cd ./rootfs5.gz   >> ./initrd64
xz --single-stream -cd ./rootfs4.gz   >> ./initrd64
xz --single-stream -cd ./rootfs3.gz   >> ./initrd64
xz --single-stream -cd ./rootfs2.gz   >> ./initrd64
xz --single-stream -cd ./rootfs1.gz64 >> ./initrd64
xz --threads=1 --format=lzma --check=crc32 --lzma1=dict=64MiB,lc=3,lp=0,pb=2,mode=normal,nice=273,mf=bt4,depth=0 < ./initrd64 > ./initrd64.lzma
#
sudo umount /mnt
#
