#!/bin/sh
#
# UPSTREAM REPOSITORY SETTINGS
#
GIT_WEB="https://raw.githubusercontent.com"
GIT_USER="mikebdp2"
GIT_REPO="floppinux-amd64net"
GIT_OFFSET="refs/heads/main/linux-slitaz"
GIT_BASEURL="${GIT_WEB}/${GIT_USER}/${GIT_REPO}/${GIT_OFFSET}"
# KEXEC
            rm -f "./kexec"
wget "${GIT_BASEURL}/kexec"
         chmod +x "./kexec"
            rm -f "./kexec.txt"
wget "${GIT_BASEURL}/kexec.txt"
# KERNEL
            rm -f "./bzImage32"
wget "${GIT_BASEURL}/bzImage32"
            rm -f "./bzImage64"
wget "${GIT_BASEURL}/bzImage64"
# ROOTFS
            rm -f "./initrd32.lzma"
wget "${GIT_BASEURL}/initrd32.lzma"
            rm -f "./initrd64.lzma"
wget "${GIT_BASEURL}/initrd64.lzma"
# SCRIPT
            rm -f "./run-slitaz.sh"
wget "${GIT_BASEURL}/run-slitaz.sh"
         chmod +x "./run-slitaz.sh"
            rm -f "./slitaz32.sh"
wget "${GIT_BASEURL}/slitaz32.sh"
         chmod +x "./slitaz32.sh"
            rm -f "./slitaz32-s.sh"
wget "${GIT_BASEURL}/slitaz32-s.sh"
         chmod +x "./slitaz32-s.sh"
            rm -f "./slitaz64.sh"
wget "${GIT_BASEURL}/slitaz64.sh"
         chmod +x "./slitaz64.sh"
            rm -f "./slitaz64-s.sh"
wget "${GIT_BASEURL}/slitaz64-s.sh"
         chmod +x "./slitaz64-s.sh"
#
