#!/bin/sh
#
# UPSTREAM REPOSITORY SETTINGS
#
GIT_WEB="https://raw.githubusercontent.com"
GIT_USER="mikebdp2"
GIT_REPO="floppinux-amd64net"
GIT_OFFSET="refs/heads/main/linux-artix"
GIT_BASEURL="${GIT_WEB}/${GIT_USER}/${GIT_REPO}/${GIT_OFFSET}"
# KEXEC
            rm -f "./kexec"
wget "${GIT_BASEURL}/kexec"
         chmod +x "./kexec"
            rm -f "./kexec.txt"
wget "${GIT_BASEURL}/kexec.txt"
# KERNEL
            rm -f "./vmlinuz-linux"
wget "${GIT_BASEURL}/vmlinuz-linux"
            rm -f "./vmlinuz-linux-hardened"
wget "${GIT_BASEURL}/vmlinuz-linux-hardened"
# ROOTFS
            rm -f "./rootfs-wirtl.cpio.lzma"
wget "${GIT_BASEURL}/rootfs-wirtl.cpio.lzma"
# SCRIPT
            rm -f "./vmlinuz-linux.sh"
wget "${GIT_BASEURL}/vmlinuz-linux.sh"
         chmod +x "./vmlinuz-linux.sh"
            rm -f "./vmlinuz-linux-s.sh"
wget "${GIT_BASEURL}/vmlinuz-linux-s.sh"
         chmod +x "./vmlinuz-linux-s.sh"
            rm -f "./vmlinuz-linux-hardened.sh"
wget "${GIT_BASEURL}/vmlinuz-linux-hardened.sh"
         chmod +x "./vmlinuz-linux-hardened.sh"
            rm -f "./vmlinuz-linux-hardened-s.sh"
wget "${GIT_BASEURL}/vmlinuz-linux-hardened-s.sh"
         chmod +x "./vmlinuz-linux-hardened-s.sh"
#
