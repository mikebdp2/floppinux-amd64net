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
# KIRC
wget "${GIT_BASEURL}/kirc"
wget "${GIT_BASEURL}/kirc.sh"
wget "${GIT_BASEURL}/kirc.txt"
chmod +x "./kirc"
chmod +x "./kirc.sh"
# OPENSSL
wget "${GIT_BASEURL}/openssl"
wget "${GIT_BASEURL}/openssl.txt"
chmod +x "./openssl"
# LINKS
wget "${GIT_BASEURL}/links"
wget "${GIT_BASEURL}/links.txt"
chmod +x "./links"
#
