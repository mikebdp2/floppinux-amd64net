#!/bin/sh
#
# UPSTREAM REPOSITORY SETTINGS
#
GIT_WEB="https://raw.githubusercontent.com"
GIT_USER="mikebdp2"
GIT_REPO="floppinux-amd64net"
GIT_OFFSET="refs/heads/main/linux-slitaz"
GIT_BASEURL="${GIT_WEB}/${GIT_USER}/${GIT_REPO}/${GIT_OFFSET}"
# GET SLITAZ
            rm -f "./get-slitaz.sh"
wget "${GIT_BASEURL}/get-slitaz.sh"
         chmod +x "./get-slitaz.sh"
                  "./get-slitaz.sh"
# RUN SLITAZ
            rm -f "./run-slitaz.sh"
wget "${GIT_BASEURL}/run-slitaz.sh"
         chmod +x "./run-slitaz.sh"
                  "./run-slitaz.sh"
#
