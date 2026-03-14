#!/bin/sh
#
# UPSTREAM REPOSITORY SETTINGS
#
GIT_WEB="https://raw.githubusercontent.com"
GIT_USER="mikebdp2"
GIT_REPO="floppinux-amd64net"
GIT_OFFSET="refs/heads/main/repository"
GIT_BASEURL="${GIT_WEB}/${GIT_USER}/${GIT_REPO}/${GIT_OFFSET}"
#
# WGET THE SOFTWARE
#
# KEXEC
            rm -f "./kexec"
wget "${GIT_BASEURL}/kexec"
         chmod +x "./kexec"
            rm -f "./kexec.txt"
wget "${GIT_BASEURL}/kexec.txt"
# KIRC
            rm -f "./kirc"
wget "${GIT_BASEURL}/kirc"
         chmod +x "./kirc"
            rm -f "./kirc.sh"
wget "${GIT_BASEURL}/kirc.sh"
         chmod +x "./kirc.sh"
            rm -f "./kirc.txt"
wget "${GIT_BASEURL}/kirc.txt"
# OPENSSL
            rm -f "./openssl"
wget "${GIT_BASEURL}/openssl"
         chmod +x "./openssl"
            rm -f "./openssl.txt"
wget "${GIT_BASEURL}/openssl.txt"
# LINKS
            rm -f "./links"
wget "${GIT_BASEURL}/links"
         chmod +x "./links"
            rm -f "./links.txt"
wget "${GIT_BASEURL}/links.txt"
# SLITAZ
            rm -f "./slitaz.sh"
wget "${GIT_BASEURL}/slitaz.sh"
         chmod +x "./slitaz.sh"
#
