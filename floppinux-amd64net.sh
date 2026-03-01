#!/usr/bin/env sh
#
#    floppinux-amd64net.sh: FLOPPINUX-AMD64NET build script, 01 Mar 2026.
#
#   Produces a FLOPPINUX-AMD64NET floppy to use as a virtual floppy at the
#    coreboot-supported AMD-no-PSP-backdoor boards that I am maintaining :
#  Lenovo G505S laptop, ASUS A88XM-E & AM1I-A desktops, ASUS KGPE-D16 server.
#   More info at: http://dangerousprototypes.com/docs/Lenovo_G505S_hacking
#    https://github.com/mikebdp2/floppinux-amd64net/blob/main/floppinux.md
#
#      Please send your feedback to Mike Banon <mikebdp2@gmail.com>.
#    Released under the terms of GNU GPL v3 by Free Software Foundation.
#

# STOP IF ANY ERRORS
set -e
#
# USER BUILD SETTINGS
#
# Multithreads: "-j$(nproc)" - enable, " " - disable
THREAD_SETTINGS="-j$(nproc)"
# Enforce the file/dir/ln EPOCH_TIME timestamps
TOUCHER_ENABLED="1"
# Working directory, will be auto-created
WORKDIR="$(pwd)/my-floppy-distro"
# Toolchain compiler, will be auto-installed
MUSLCC="${WORKDIR}/x86_64-linux-musl-cross/bin/x86_64-linux-musl-gcc"

#
# UPSTREAM REPOSITORY SETTINGS
#
GIT_WEB="https://raw.githubusercontent.com"
GIT_USER="mikebdp2"
GIT_REPO="floppinux-amd64net"
GIT_OFFSET="refs/heads/main"
GIT_BASEURL="${GIT_WEB}/${GIT_USER}/${GIT_REPO}/${GIT_OFFSET}"

#
# GLOBAL ENVARS FOR THE MAKE COMMANDS
#
# Architecture
export ARCH="x86_64"
# Timezone
export TZ="UTC"
# Locale
export LC_ALL="C"
export LANG="C"
# Epoch value should have lots of zeroes if converted to a hex format, i.e. 1770094592
export EPOCH_TIME="0"
export EPOCH_TIME_HEX=$(printf "0x%08x" "$EPOCH_TIME")
export TOUCH_TIME=$(date -u -d @$EPOCH_TIME +%Y%m%d%H%M.%S)
export KBUILD_BUILD_TIMESTAMP="$(date -u -d @$EPOCH_TIME '+%a %b %e %H:%M:%S %Z %Y')"
export SOURCE_DATE_EPOCH="$EPOCH_TIME"
# User and host
export KBUILD_BUILD_USER="anon"
export KBUILD_BUILD_HOST="host"

# Keys
  enter=$( printf '\015' )
 ctrl_c=$( printf '\003' )
 ctrl_x=$( printf '\030' )
 ctrl_z=$( printf '\032' )
# Formatting
   bold="\e[1m"
   bred="\e[1;31m"
 bgreen="\e[1;32m"
byellow="\e[1;33m"
   bend="\e[0m"

# Escape a '$1' string for use as a replacement in sed s/// command with delimiter '|'
# This escapes &, |, and \ (special in the replacement part)
escape_sed_repl () {
    printf '%s\n' "$1" | sed -e 's/[&|\\]/\\&/g'
}
WORKDIR_ESC=$(escape_sed_repl "$WORKDIR")

# Waits until a user presses Enter.
encontinue () {
    printf "\npress [ENTER] to continue... "
    encontinue_old_stty_cfg=$( stty -g )
    stty raw -echo
    while true ; do
        encontinue_answer=$( head -c 1 )
        case "$encontinue_answer" in
            *"$ctrl_c"*|"$ctrl_x"*|"$ctrl_z"*)
                stty "$encontinue_old_stty_cfg"
                printf "${bred}TERMINATED${bend}\n"
                exit 1
                ;;
            *"$enter"*)
                stty "$encontinue_old_stty_cfg"
                printf "\n"
                return 0
                ;;
        esac
    done
}

# Checks if a command '$1' exists.
command_exists () {
    if [ ! -x "$( command -v "$1" )" ] ; then
        printf "\n${bred}ERROR${bend}: command ${byellow}$1${bend} is not found !\n"
        printf "       Please install ${bgreen}$2${bend} if you are on Artix Linux\n"
        encontinue
        return 1
    else
        return 0
    fi
}

# Checks if all the required commands exist.
commands_check () {
    if ! command_exists "bc" "bc" || \
       ! command_exists "bison" "bison" || \
       ! command_exists "cmake" "cmake" || \
       ! command_exists "cpio" "cpio" || \
       ! command_exists "fakeroot" "fakeroot" || \
       ! command_exists "fasm" "fasm" || \
       ! command_exists "flex" "flex" || \
       ! command_exists "gcc" "gcc" || \
       ! command_exists "git" "git" || \
       ! command_exists "make" "make" || \
       ! command_exists "mcopy" "mtools" || \
       ! command_exists "mkdosfs" "dosfstools" || \
       ! command_exists "nasm" "nasm" || \
       ! command_exists "ncursesw6-config" "ncurses" || \
       ! command_exists "patch" "patch" || \
       ! command_exists "sha256sum" "coreutils" || \
       ! command_exists "strip" "binutils" || \
       ! command_exists "sstrip" "elfkickers" || \
       ! command_exists "strip-nondeterminism" "strip-nondeterminism" || \
       ! command_exists "sudo" "sudo" || \
       ! command_exists "syslinux" "syslinux" || \
       ! command_exists "wget" "wget" ; then
        exit 1
    fi
}

# Checks if a file '$1' exists.
file_exists () {
    if [ ! -f "$1" ] ; then
        # printf "\n${byellow}WARNING${bend}: file ${byellow}$1${bend} is not found !\n"
        # encontinue
        return 1
    else
        return 0
    fi
}

# Checks if a directory '$1' exists.
dir_exists () {
    if [ ! -d "$1" ] ; then
        # printf "\n${byellow}WARNING${bend}: directory ${byellow}$1${bend} is not found !\n"
        # encontinue
        return 1
    else
        return 0
    fi
}

# Force removes a '$2' object and then moves a '$1' object to '$2' location.
mover () {
    if file_exists "$1" || dir_exists "$1" ; then
        rm -rf "$2"
        mv "$1" "$2"
        return 0
    else
        printf "\n${bred}ERROR${bend}: object ${byellow}$1${bend} is not found !\n"
        exit 1
    fi
}

# Downloads a file '$1' from a link '$2' using the options '$3' and checks if this was successful.
wgetter () {
    rm -f "$1"
    if [ -z "$3" ] ; then
        wget "$2"
    else
        wget "$3" "$2"
    fi
    if [ -f "$1" ] ; then
        wgetter_file_size=$(($( wc -c < "$1" )))
        if [ "$wgetter_file_size" -eq "0" ] ; then
            rm -f "$1"
        fi
    fi
    if [ ! -f "$1" ] ; then
        printf "\n${bred}ERROR${bend}: cannot download a ${byellow}$1${bend} file !"
        printf "\n       Please check your Internet connection and try again.\n"
        exit 1
    else
        sleep 1
        return 0
    fi
}

# Prints the status message in '$1: $2' format with a green color highlighting of a '$1'.
printgr () {
    printf "${bgreen}$1${bend}: $2\n"
    return 0
}

# Prints the notification message in '$1: $2' format with a yellow color highlighting of a '$1'.
printye () {
    printf "${byellow}$1${bend}: $2\n"
    return 0
}

# Prints the error message in '$1: $2' format with a red color highlighting of a '$1'.
printrd () {
    printf "${bred}$1${bend}: $2\n"
    return 0
}


# Check if a git clone of '$1' has been successful.
git_clone_check () {
    if [ ! -d "$1" ] ; then
        printf "\n${byellow}WARNING${bend}: cannot download a ${byellow}$1${bend} repository !"
        printf "\n         Please check your Internet connection and try again.\n"
        encontinue
        return 1
    else
        return 0
    fi
}

# Changes the dir '$2' modification time to '$1', also in a "sudo" mode if '$3' argument is set to "sudo".
toucher_dir () {
    if [ "$TOUCHER_ENABLED" = "0" ] ; then
        return 0
    fi
    if [ "$3" = "sudo" ] ; then
        find "$2" -print0 | sudo env TZ="UTC" LC_ALL="C" LANG="C" \
            xargs -0 touch -h -t "$1" 2>/dev/null || true
    else
        find "$2" -print0 | \
            xargs -0 touch -h -t "$1" 2>/dev/null || true
    fi
    return 0
}

# Changes the file '$2' modification time to '$1', also in a "sudo" mode if '$3' argument is set to "sudo".
toucher_file () {
    if [ "$TOUCHER_ENABLED" = "0" ] ; then
        return 0
    fi
    if [ "$3" = "sudo" ] ; then
        sudo env TZ="UTC" LC_ALL="C" LANG="C" \
            touch -h -t "$1" "$2" 2>/dev/null
    else
            touch -h -t "$1" "$2" 2>/dev/null
    fi
    return 0
}

# MUSL toolchain
musl_get () {
    printgr "MUSL" "remove the old directory if it exists"
    rm -rf ./x86_64-linux-musl-cross/
    printgr "MUSL" "wget the archive with a toolchain"
    wgetter "./x86_64-linux-musl-cross.tgz" "https://musl.cc/x86_64-linux-musl-cross.tgz"
    tar -xvf ./x86_64-linux-musl-cross.tgz
    return 0
}

# Build a specific '$1' version of a Linux kernel
linux_build_ver () {
    if [ -z "$1" ] ; then
        printf "\n${bred}ERROR${bend}: kernel version is not specified !\n"
        encontinue
        return 1
    else
        case "$1" in
            *"ath"*|*"pcn"*|*"rtl"*)
                printgr "LINUX-$1" "create a directory"
                rm -rf ./linux-$1/
                cp -r ./linux/ ./linux-$1/
                cd ./linux-$1/
                printgr "LINUX-$1" "wget a .config file to configure the source code"
                wgetter "./linux-$1.cfg" "${GIT_BASEURL}/configs/linux-$1.cfg"
                mover "./linux-$1.cfg" "./.config"
                printgr "LINUX-$1" "build the source code"
                    toucher_dir "$TOUCH_TIME" "./"
                make bzImage "$THREAD_SETTINGS"
                    toucher_dir "$TOUCH_TIME" "./"
                cd ./../
                printgr "LINUX-$1" "create a symbolic link"
                                                      rm -f "./bzImage-$1"
                ln -s "./linux-$1/arch/x86_64/boot/bzImage" "./bzImage-$1"
                    toucher_file "$TOUCH_TIME" "./bzImage-$1"
                printgr "LINUX-$1" "print a size of a kernel"
                ls -alL ./bzImage-$1
                ;;
            *)
                printf "\n${bred}ERROR${bend}: unsupported ${byellow}$1${bend} kernel version !\n\n"
                exit 1
                ;;
        esac
    fi
    return 0
}

# Linux kernel
linux_build () {
    printgr "LINUX" "remove the old directory if it exists"
    rm -rf ./linux/
    while [ ! -d "./linux/" ] ; do
        printgr "LINUX" "git clone a repository"
        git clone --depth=1 --branch v6.18.15 "https://github.com/gregkh/linux.git"
        git_clone_check "./linux/"
    done
    cd ./linux/
    printgr "LINUX" "upgrade the source code to -Oz optimization level"
    mover ./.git/ ./../temp.git/ # Temporarily move ./.git/ to avoid damaging its contents in the process
    for opt in O1 O2 O3 Os ; do
        printgr "LINUX" "replace -$opt with -Oz optimization level..."
        find . -type f -print0 | xargs -0 sed -i -e "s/-$opt/-Oz/g"
    done
    mover ./../temp.git/ ./.git/
    git add .
    git commit -m "LINUX: upgrade the source code to -Oz optimization level"
    printgr "LINUX" "patch to disable the MICROCODE and NET_SELFTESTS configs"
    wgetter "./linux.patch" "${GIT_BASEURL}/patches/linux.patch"
    patch -p1 < ./linux.patch
    git add ./arch/x86/Kconfig
    git add ./net/Kconfig
    git commit -m "LINUX: disable the MICROCODE and NET_SELFTESTS configs"
    cd ./../
    linux_build_ver "ath"
    linux_build_ver "pcn"
    linux_build_ver "rtl"
    return 0
}

# Dropbear SSH client and SCP utility
dropbear_build () {
    printgr "DROPBEAR" "remove the old directory if it exists"
    rm -rf ./dropbear/
    while [ ! -d "./dropbear/" ] ; do
        printgr "DROPBEAR" "git clone a repository"
        git clone --depth=1 --branch DROPBEAR_2025.89 "https://github.com/mkj/dropbear.git"
        git_clone_check "./dropbear/"
    done
    cd ./dropbear/
    printgr "DROPBEAR" "configure the source code"
    ./configure --host=x86_64-linux-musl --prefix=/usr --enable-static --disable-zlib --disable-syslog --disable-lastlog --disable-utmp --disable-utmpx --disable-wtmp --disable-wtmpx --disable-shadow --enable-bundled-libtom --disable-openpty --disable-loginfunc --disable-pututline --disable-pututxline --without-pam --disable-plugin \
    CC="${MUSLCC}" \
    CFLAGS="-DDROPBEAR_ECDSA=0 -DDROPBEAR_ECDH=0 -static -Os -s -ffunction-sections -fdata-sections -fno-unwind-tables -fno-asynchronous-unwind-tables -fno-stack-protector -fomit-frame-pointer -fmerge-all-constants -fno-ident -fno-math-errno -fno-unroll-loops -ffast-math -fno-exceptions -march=x86-64 -mtune=generic -fno-align-functions -fno-align-jumps -fno-align-loops -fno-align-labels -fno-pie -I${WORKDIR}/x86_64-linux-musl-cross/include --sysroot=${WORKDIR}/x86_64-linux-musl-cross -fno-strict-aliasing" \
    LDFLAGS="-L${WORKDIR}/x86_64-linux-musl-cross/lib -L${WORKDIR}/x86_64-linux-musl-cross/x86_64-linux-musl/lib -static -s -Wl,--gc-sections -Wl,--strip-all -Wl,--build-id=none -Wl,-z,norelro -Wl,--hash-style=sysv -Wl,--no-eh-frame-hdr -Wl,-z,noseparate-code -Wl,--no-undefined-version -Wl,--as-needed -Wl,--sort-common -Wl,--sort-section=alignment -Wl,--compress-debug-sections=none -Wl,--warn-common -Wl,--discard-all -Wl,--discard-locals -Wl,--no-ld-generated-unwind-info -Wl,--orphan-handling=place -no-pie -L${WORKDIR}/x86_64-linux-musl-cross/lib --sysroot=${WORKDIR}/x86_64-linux-musl-cross"
    printgr "DROPBEAR" "build the source code"
        toucher_dir "$TOUCH_TIME" "./"
    make CC="${MUSLCC}" PROGRAMS="dbclient" dbclient scp "$THREAD_SETTINGS"
        toucher_dir "$TOUCH_TIME" "./"
    printgr "DROPBEAR" "sstrip the binaries"
    sstrip ./dbclient
        toucher_file "$TOUCH_TIME" "./dbclient"
    sstrip ./scp
        toucher_file "$TOUCH_TIME" "./scp"
    printgr "DROPBEAR" "create a symbolic link"
                 rm -f "./ssh"
    ln -s "./dbclient" "./ssh"
    printgr "DROPBEAR" "print the sizes of binaries"
    ls -alL ./dbclient
    ls -alL ./scp
    cd ./../
    return 0
}

# libnl-tiny library needed for wpa_supplicant
libnl_build () {
    printgr "LIBNL-TINY" "remove the old directory if it exists"
    rm -rf ./libnl-tiny/
    while [ ! -d "./libnl-tiny/" ] ; do
        printgr "LIBNL-TINY" "git clone a repository"
        git clone --depth=1 "https://github.com/openwrt/libnl-tiny.git"
        git_clone_check "./libnl-tiny/"
    done
    cd ./libnl-tiny/
    printgr "LIBNL-TINY" "patch to setup the variables"
    wgetter "./libnl-tiny.patch" "${GIT_BASEURL}/patches/libnl-tiny.patch"
    sed -i -e 's|/home/artix/my-floppy-distro|'"${WORKDIR_ESC}"'|g' ./libnl-tiny.patch
    patch -p1 < ./libnl-tiny.patch
    ### printgr "LIBNL-TINY" "patch to fix ucred structure for libnl-tiny build"
    ### wgetter "./libnl-tiny_ucred_off.patch" "${GIT_BASEURL}/patches/libnl-tiny_ucred_off.patch"
    ### patch -p1 < ./libnl-tiny_ucred_off.patch
    ### printgr "LIBNL-TINY" "patch to remove the bug information for now (contains the full file paths)"
    ### wgetter "./libnl-tiny_nobuginfo.patch" "${GIT_BASEURL}/patches/libnl-tiny_nobuginfo.patch"
    ### patch -p1 < ./libnl-tiny_nobuginfo.patch
    rm -rf ./build/
    mkdir ./build/
    cd ./build/
    printgr "LIBNL-TINY" "configure the source code for toolchain directory installation"
    cmake -DCMAKE_INSTALL_PREFIX="${WORKDIR}/x86_64-linux-musl-cross/usr/" ..
    printgr "LIBNL-TINY" "build the source code"
        toucher_dir "$TOUCH_TIME" "./"
    make "$THREAD_SETTINGS"
        toucher_dir "$TOUCH_TIME" "./"
    printgr "LIBNL-TINY" "install the library to a toolchain directory"
    make install
    cd ./../
    ### printgr "LIBNL-TINY" "patch to fix ucred structure for external usage by wpa_supplicant"
    ### wgetter "./libnl-tiny_ucred_on.patch" "${GIT_BASEURL}/libnl-tiny_ucred_on.patch"
    ### cd "${WORKDIR}/x86_64-linux-musl-cross/usr/include/libnl-tiny/"
    ### patch -p1 < "${WORKDIR}/libnl-tiny/libnl-tiny_ucred_on.patch"
    ### cd "${WORKDIR}/libnl-tiny/"
    cd ./../
    return 0
}

# wpa_supplicant daemon and wpa_cli utility for connecting to WiFi networks
wpa_build () {
    printgr "WPA" "remove the old directory if it exists"
    rm -rf ./hostap/
    while [ ! -d "./hostap/" ] ; do
        printgr "WPA" "git clone a repository"
        git clone --depth=1 --branch hostap_2_11 "https://github.com/mikebdp2/hostap.git"
        git_clone_check "./hostap/"
    done
    cd ./hostap/
    printgr "WPA" "patch to fix linking with a libnl-tiny library"
    wgetter "./wpa_libnl.patch" "${GIT_BASEURL}/patches/wpa_libnl.patch"
    patch -p1 < ./wpa_libnl.patch
    printgr "WPA" "wget a .config file to configure the source code"
    wgetter "./wpa.cfg" "${GIT_BASEURL}/configs/wpa.cfg"
    mover "./wpa.cfg" "./wpa_supplicant/.config"
    cd ./../
    printgr "WPA_SUPPLICANT" "remove the old directory if it exists and create a new directory"
    mover ./hostap/ ./wpa_supplicant/
    printgr "WPA_CLI" "remove the old directory if it exists and create a new directory"
    rm -rf ./wpa_cli/
    cp -r ./wpa_supplicant/ ./wpa_cli/
    cd ./wpa_supplicant/
    printgr "WPA_SUPPLICANT" "patch to setup the variables"
    wgetter "./wpa_supplicant.patch" "${GIT_BASEURL}/patches/wpa_supplicant.patch"
    sed -i -e 's|/home/artix/my-floppy-distro|'"${WORKDIR_ESC}"'|g' ./wpa_supplicant.patch
    patch -p1 < ./wpa_supplicant.patch
    cd ./wpa_supplicant/
    printgr "WPA_SUPPLICANT" "build the source code"
        toucher_dir "$TOUCH_TIME" "./"
    make CC="${MUSLCC}" wpa_supplicant "$THREAD_SETTINGS"
        toucher_dir "$TOUCH_TIME" "./"
    printgr "WPA_SUPPLICANT" "sstrip the binary"
    sstrip ./wpa_supplicant
        toucher_file "$TOUCH_TIME" "./wpa_supplicant"
    printgr "WPA_SUPPLICANT" "print a size of a binary"
    ls -alL ./wpa_supplicant
    cd ./../../wpa_cli/
    printgr "WPA_CLI" "patch to setup the variables"
    wgetter "./wpa_cli.patch" "${GIT_BASEURL}/patches/wpa_cli.patch"
    sed -i -e 's|/home/artix/my-floppy-distro|'"${WORKDIR_ESC}"'|g' ./wpa_cli.patch
    patch -p1 < ./wpa_cli.patch
    cd ./wpa_supplicant/
    printgr "WPA_CLI" "build the source code"
        toucher_dir "$TOUCH_TIME" "./"
    make CC="${MUSLCC}" wpa_cli "$THREAD_SETTINGS"
        toucher_dir "$TOUCH_TIME" "./"
    printgr "WPA_CLI" "sstrip the binary"
    sstrip ./wpa_cli
        toucher_file "$TOUCH_TIME" "./wpa_cli"
    printgr "WPA_CLI" "print a size of a binary"
    ls -alL ./wpa_cli
    cd ./../../
    return 0
}

# linux-firmware needed for some Ethernet/WiFi network adapters
firmware_get () {
    printgr "LINUX-FIRMWARE" "remove the old directory if it exists"
    rm -rf ./linux-firmware/
    while [ ! -d "./linux-firmware/" ] ; do
        printgr "LINUX-FIRMWARE" "git clone a repository"
        git clone --depth=1 "https://github.com/mikebdp2/linux-firmware.git"
        git_clone_check "./linux-firmware/"
    done
    return 0
}

# kirc simple IRC client
kirc_build () {
    printgr "KIRC" "remove the old directory if it exists"
    rm -rf ./kirc/
    while [ ! -d "./kirc/" ] ; do
        printgr "KIRC" "git clone a repository"
        git clone --depth=1 --branch 1.2.2 "https://github.com/mcpcpc/kirc.git"
        git_clone_check "./kirc/"
    done
    cd ./kirc/
    printgr "KIRC" "patch to setup the variables"
    wgetter "./kirc.patch" "${GIT_BASEURL}/patches/kirc.patch"
    patch -p1 < "./kirc.patch"
    printgr "KIRC" "build the source code"
        toucher_dir "$TOUCH_TIME" "./"
    make CC="${MUSLCC}" "$THREAD_SETTINGS"
        toucher_dir "$TOUCH_TIME" "./"
    printgr "KIRC" "sstrip a binary"
    sstrip ./kirc
        toucher_file "$TOUCH_TIME" "./kirc"
    printgr "KIRC" "print a size of a binary"
    ls -alL ./kirc
    printgr "KIRC" "generate a user manual"
    man ./kirc.1 > ./kirc.txt
        toucher_file "$TOUCH_TIME" "./kirc.txt"
    cd ./../
    return 0
}

# Build a specific '$1' version of a Busybox filesystem
busybox_build_ver () {
    if [ -z "$1" ] ; then
        printf "\n${bred}ERROR${bend}: busybox version is not specified !\n"
        encontinue
        return 1
    else
        case "$1" in
            *"nortl"*|*"wirtl"*)
                printgr "BUSYBOX-$1" "remove the old rootfs directory and archives"
                rm -f ./rootfs-$1.cpio
                rm -f ./rootfs-$1.cpio.lzma
                rm -rf ./filesystem-$1/
                printgr "BUSYBOX-$1" "create a new rootfs directory"
                cp -r ./filesystem/ ./filesystem-$1/
                cd ./filesystem-$1/
                    toucher_dir "$TOUCH_TIME" "./"
                if [ "$1" = "wirtl" ] ; then
                    printgr "BUSYBOX-$1" "copy the Realtek firmware files"
                    mkdir -p ./lib/firmware/rtl_nic/
                    find ./../linux-firmware/rtl_nic/ -name "rtl816*" | \
                        sort | while IFS= read -r file ; do \
                        cp "$file" ./lib/firmware/rtl_nic/ ; \
                        toucher_dir "$TOUCH_TIME" "./lib/firmware/rtl_nic/" ; \
                    done
                fi
                fakeroot sh -c '
                    set -e
                    printgr () { bgreen="\e[1;32m" ; bend="\e[0m" ; printf "${bgreen}$1${bend}: $2\n" ; return 0 ; }
                    printgr "BUSYBOX-'"$1"'" "create the device nodes"
                    mknod ./dev/console c 5 1
                    mknod ./dev/null    c 1 3
                    printgr "BUSYBOX-'"$1"'" "give the ownership to root"
                    chown -R root:root ./
                    printgr "BUSYBOX-'"$1"'" "change the files/dirs modification time"
                    find "./" -print0 | xargs -0 touch -h -t "'"$TOUCH_TIME"'" 2>/dev/null || true
                    printgr "BUSYBOX-'"$1"'" "create a rootfs archive"
                    LC_ALL="C" LANG="C" find . -print0 | LC_ALL="C" LANG="C" sort -z | cpio -0 -H newc -o --reproducible 2>/dev/null > ./../rootfs-'"$1"'.cpio || exit 1
                '
                    toucher_file "$TOUCH_TIME" "./../rootfs-$1.cpio"
                strip-nondeterminism -t cpio -T $EPOCH_TIME ./../rootfs-$1.cpio
                    toucher_file "$TOUCH_TIME" "./../rootfs-$1.cpio"
                printgr "BUSYBOX-$1" "compress a rootfs archive"
                xz --threads=1 --format=lzma --check=crc32 --lzma1=dict=64MiB,lc=3,lp=0,pb=2,mode=normal,nice=273,mf=bt4,depth=0 < ./../rootfs-$1.cpio > ./../rootfs-$1.cpio.lzma
                    toucher_file "$TOUCH_TIME" "./../rootfs-$1.cpio.lzma"
                cd ./../
                printgr "BUSYBOX-$1" "print a size of a rootfs archive"
                ls -alL ./rootfs-$1.cpio.lzma
                ;;
            *)
                printf "\n${bred}ERROR${bend}: unsupported ${byellow}$1${bend} busybox version !\n\n"
                exit 1
                ;;
        esac
    fi
    return 0
}

# Busybox filesystem used by a Linux kernel
busybox_build () {
    printgr "BUSYBOX" "remove the old directory if it exists"
    rm -rf ./busybox/
    while [ ! -d "./busybox/" ] ; do
        printgr "BUSYBOX" "git clone a repository"
        git clone --depth=1 --branch 1_37_stable "https://github.com/mikebdp2/busybox.git"
        git_clone_check "./busybox/"
    done
    cd ./busybox/
    printgr "BUSYBOX" "upgrade the source code to -Os optimization level (no -Oz yet)"
    mover ./.git/ ./../temp.git/ # Temporarily move ./.git/ to avoid damaging its contents in the process
    printgr "BUSYBOX" "replace -O2 with -Os optimization level... (no -Oz yet)"
    find . -type f -print0 | xargs -0 sed -i -e "s/-O2/-Os/g"
    mover ./../temp.git/ ./.git/
    git add .
    git commit -m "BUSYBOX: upgrade the source code to -Os optimization level (no -Oz yet)"
    printgr "BUSYBOX" "fix for host OS like Arch/Artix Linux with GCC 14 or newer"
    sed -i "s/main() {}/int main() {}/" ./scripts/kconfig/lxdialog/check-lxdialog.sh
    printgr "BUSYBOX" "wget a .config file to configure the source code"
    wgetter "./busybox.cfg" "${GIT_BASEURL}/configs/busybox.cfg"
    mover "./busybox.cfg" "./.config"
    printgr "BUSYBOX" "setup the variables"
    sed -i -e 's|.*CONFIG_CROSS_COMPILER_PREFIX.*|CONFIG_CROSS_COMPILER_PREFIX="'"${WORKDIR_ESC}"'/x86_64-linux-musl-cross/bin/x86_64-linux-musl-"|' ./.config
    sed -i -e 's|.*CONFIG_SYSROOT.*|CONFIG_SYSROOT="'"${WORKDIR_ESC}"'"|' ./.config
    sed -i -e 's|.*CONFIG_EXTRA_CFLAGS.*|CONFIG_EXTRA_CFLAGS="-I'"${WORKDIR_ESC}"'/x86_64-linux-musl-cross/include -static -Os -s -ffunction-sections -fdata-sections -fno-unwind-tables -fno-asynchronous-unwind-tables -fno-stack-protector -fomit-frame-pointer -fmerge-all-constants -fno-ident -fno-math-errno -fno-unroll-loops -ffast-math -fvisibility=hidden -fno-exceptions -march=x86-64 -mtune=generic -fno-align-functions -fno-align-jumps -fno-align-loops -fno-align-labels -fno-pie"|' ./.config
    sed -i -e 's|.*CONFIG_EXTRA_LDFLAGS.*|CONFIG_EXTRA_LDFLAGS="-L'"${WORKDIR_ESC}"'/x86_64-linux-musl-cross/lib -static -s -Wl,--gc-sections -Wl,--strip-all -Wl,--build-id=none -Wl,-z,norelro -Wl,--hash-style=sysv -Wl,--no-eh-frame-hdr -Wl,-z,noseparate-code -Wl,--no-undefined-version -Wl,--as-needed -Wl,--sort-common -Wl,--sort-section=alignment -Wl,--compress-debug-sections=none -Wl,--warn-common -Wl,--fatal-warnings -Wl,--discard-all -Wl,--discard-locals -Wl,--no-ld-generated-unwind-info -Wl,--orphan-handling=place -no-pie"|' ./.config
    printgr "BUSYBOX" "build the source code"
        toucher_dir "$TOUCH_TIME" "./"
    make "$THREAD_SETTINGS"
    printgr "BUSYBOX" "sstrip a binary"
    sstrip ./busybox
    ls -alL ./busybox
    printgr "BUSYBOX" "generate the initial filesystem"
    rm -rf ./_install/
    make install
        toucher_dir "$TOUCH_TIME" "./"
    rm -rf ./../filesystem/
    cp -r ./_install/ ./../filesystem/
    cd ./../filesystem/
        toucher_dir "$TOUCH_TIME" "./"
    printgr "BUSYBOX" "create the filesystem directories"
    for dir in dev proc etc/init.d sys tmp home var/run lib/firmware/ath9k_htc ; do
        mkdir -p "./$dir"
    done
        toucher_dir "$TOUCH_TIME" "./"
    printgr "BUSYBOX" "wget a welcome message"
    ### wgetter "./welcome" "${GIT_BASEURL}/welcome"
    rm -f  ./welcome
    cat >> ./welcome << EOF
______________ FLOPPINUX_V_0.3.1-AMD64NET (2026.03) _____________
__________ AN_EMBEDDED_SINGLE_FLOPPY_LINUX_DISTRIBUTION _________
_________ BY_KRZYSZTOF_KRYSTIAN_JANKOWSKI_AND_MIKE_BANON ________
EOF
        toucher_file "$TOUCH_TIME" "./welcome"
    printgr "BUSYBOX" "create an inittab file"
    rm -f  ./etc/inittab
    cat >> ./etc/inittab << EOF
::sysinit:/etc/init.d/rc
::askfirst:/usr/bin/setsid /bin/cttyhack /bin/sh
::respawn:/usr/bin/setsid /bin/cttyhack /bin/sh
::restart:/sbin/init
::ctrlaltdel:/sbin/reboot
::shutdown:/bin/umount -a -r
EOF
        toucher_file "$TOUCH_TIME" "./etc/inittab"
    printgr "BUSYBOX" "wget the init rc script"
### DEBUG=1
### debug () { [ $DEBUG = 1 ] && echo ">>> $*" ; }
    wgetter "./etc_init-d_rc" "${GIT_BASEURL}/scripts/etc_init-d_rc"
    mover "./etc_init-d_rc" "./etc/init.d/rc"
    chmod +x ./etc/init.d/rc
        toucher_file "$TOUCH_TIME" "./etc/init.d/rc"
    printgr "BUSYBOX" "create the wpa_supplicant config"
    rm -f  ./etc/wpa_supplicant.conf
    cat >> ./etc/wpa_supplicant.conf << EOF
ctrl_interface=/var/run/wpa_supplicant
update_config=1
EOF
        toucher_file "$TOUCH_TIME" "./etc/wpa_supplicant.conf"
    printgr "BUSYBOX" "create the get_repo.sh script"
    rm -f  ./etc/get_repo.sh
    cat >> ./etc/get_repo.sh << EOF
wget "${GIT_BASEURL}/repo.sh"
chmod +x ./repo.sh
./repo.sh
EOF
    chmod +x ./etc/get_repo.sh
        toucher_file "$TOUCH_TIME" "./etc/get_repo.sh"
    printgr "BUSYBOX" "wget the udhcpc script"
    wgetter "./udhcpc.sh" "${GIT_BASEURL}/scripts/udhcpc.sh"
    mover "./udhcpc.sh" "./etc/udhcpc.sh"
    chmod +x ./etc/udhcpc.sh
        toucher_file "$TOUCH_TIME" "./etc/udhcpc.sh"
    printgr "BUSYBOX" "copy the external files"
    cp ./../dropbear/dbclient ./usr/bin/dbclient
        toucher_file "$TOUCH_TIME" "./usr/bin/dbclient"
    cp ./../dropbear/scp ./usr/bin/scp
        toucher_file "$TOUCH_TIME" "./usr/bin/scp"
    cp ./../wpa_supplicant/wpa_supplicant/wpa_supplicant ./usr/bin/wpa_supplicant
        toucher_file "$TOUCH_TIME" "./usr/bin/wpa_supplicant"
    cp ./../wpa_cli/wpa_supplicant/wpa_cli ./usr/bin/wpa_cli
        toucher_file "$TOUCH_TIME" "./usr/bin/wpa_cli"
    cp ./../linux-firmware/ath9k_htc/htc_9271-1.4.0.fw ./lib/firmware/ath9k_htc/htc_9271-1.4.0.fw
        toucher_file "$TOUCH_TIME" "./lib/firmware/ath9k_htc/htc_9271-1.4.0.fw"
    ### cp ./../kirc/kirc /usr/bin/kirc
    ### cp ./../kirc/kirc.txt /etc/kirc.txt
    cd ./usr/bin/
                 rm -f "./ssh"
    ln -s "./dbclient" "./ssh"
        toucher_file "$TOUCH_TIME" "./ssh"
    cd ./../../../
        toucher_dir "$TOUCH_TIME" "./filesystem/"
    busybox_build_ver "nortl"
    printgr "BUSYBOX-NORTL" "create the symbolic links"
                               rm -f "./rootfs-ath.cpio.lzma"
    ln -s "./rootfs-nortl.cpio.lzma" "./rootfs-ath.cpio.lzma"
        toucher_file "$TOUCH_TIME" "./rootfs-ath.cpio.lzma"
                               rm -f "./rootfs-pcn.cpio.lzma"
    ln -s "./rootfs-nortl.cpio.lzma" "./rootfs-pcn.cpio.lzma"
        toucher_file "$TOUCH_TIME" "./rootfs-pcn.cpio.lzma"
    busybox_build_ver "wirtl"
    printgr "BUSYBOX-WIRTL" "create a symbolic link"
                               rm -f "./rootfs-rtl.cpio.lzma"
    ln -s "./rootfs-wirtl.cpio.lzma" "./rootfs-rtl.cpio.lzma"
        toucher_file "$TOUCH_TIME" "./rootfs-rtl.cpio.lzma"
    return 0
}

# Generate the syslinux configs
syslinux_config () {
    printgr "SYSLINUX" "generate a standard config file"
    rm -f  ./syslinux.cfg
    cat >> ./syslinux.cfg << EOF
DEFAULT floppinux
LABEL floppinux
SAY [ BOOTING FLOPPINUX VERSION 0.3.1-AMD64NET ]
KERNEL bzImage
INITRD rfscpiol.zma
APPEND root=/dev/ram rdinit=/etc/init.d/rc console=tty0 tsc=unstable
EOF
    chmod +x ./syslinux.cfg
        toucher_file "$TOUCH_TIME" "./syslinux.cfg"
    printgr "SYSLINUX" "generate a debug config file"
    rm -f  ./syslinux_debug.cfg
    cat >> ./syslinux_debug.cfg << EOF
DEFAULT floppinux
LABEL floppinux
SAY [ BOOTING FLOPPINUX VERSION 0.3.1-AMD64NET DEBUG ]
KERNEL bzImage
INITRD rfscpiol.zma
APPEND root=/dev/ram rdinit=/etc/init.d/rc console=tty0 ignore_loglevel earlyprintk=tty0 loglevel=8 tsc=unstable
EOF
    chmod +x ./syslinux_debug.cfg
        toucher_file "$TOUCH_TIME" "./syslinux_debug.cfg"
    return 0
}

# Build a specific floppy version
floppinux_build () {
    if [ -z "$1" ] ; then
        printf "\n${bred}ERROR${bend}: floppy version is not specified !\n"
        encontinue
        return 1
    else
        case "$1" in
            *"ath"*|*"pcn"*|*"rtl"*)
                printgr "FLOPPINUX-$1" "create a floppy"
                rm -f ./flpnx$1.img
                dd if=/dev/zero of=./flpnx$1.img bs=1k count=2880
                printgr "FLOPPINUX-$1" "format a floppy to FAT12 filesystem"
                mkdosfs -n FLOPPINUX -i $EPOCH_TIME_HEX ./flpnx$1.img
                mdir -i ./flpnx$1.img
                printgr "FLOPPINUX-$1" "install a syslinux bootloader"
                syslinux --install ./flpnx$1.img
                mdir -i ./flpnx$1.img
                printgr "FLOPPINUX-$1" "copy a Linux kernel to ./flpnx$1.img"
                ls -alL ./bzImage-$1
                mcopy -i "./flpnx$1.img" "./bzImage-$1" ::/bzImage
                mdir -i ./flpnx$1.img
                printgr "FLOPPINUX-$1" "copy a rootfs filesystem to ./flpnx$1.img"
                ls -alL ./rootfs-$1.cpio.lzma
                mcopy -i "./flpnx$1.img" "./rootfs-$1.cpio.lzma" ::/rfscpiol.zma
                mdir -i ./flpnx$1.img
                printgr "FLOPPINUX-$1" "copy a syslinux config file to ./flpnx$1.img"
                ls -alL ./syslinux.cfg
                mcopy -i "./flpnx$1.img" "./syslinux.cfg" ::/syslinux.cfg
                mdir -i ./flpnx$1.img
                printgr "FLOPPINUX-$1" "print a sha256sum of a floppy"
                sha256sum ./flpnx$1.img
                ;;
            *)
                printf "\n${bred}ERROR${bend}: unsupported ${byellow}$1${bend} floppy version !\n\n"
                exit 1
                ;;
        esac
    fi
    return 0
}

# Print a '$1' notification message of what we need to do with sudo rights and try to elevate the privileges.
sudoer () {
        printye "SUDOER" "I need to $1"
    while ! sudo -v ; do
        printrd "SUDOER" "Authentication failed! Trying again..."
        printye "SUDOER" "I need to $1"
        sleep 1
    done
}

# Check if user.name and/or user.email GIT settings are missing - and configure them if so
git_check () {
    # Check and set user.name if missing
    if ! git config --global user.name >/dev/null 2>&1 ; then
         git config --global user.name "Your Name"
    fi
    # Check and set user.email if missing
    if ! git config --global user.email >/dev/null 2>&1 ; then
         git config --global user.email "you@example.com"
    fi
}

commands_check
printgr "MY-FLOPPY-DISTRO" "build started"
rm -rf "${WORKDIR}"
mkdir "${WORKDIR}"
cd "${WORKDIR}"
git_check
musl_get
linux_build
dropbear_build
libnl_build
wpa_build
firmware_get
kirc_build
busybox_build
syslinux_config
floppinux_build "ath"
floppinux_build "pcn"
floppinux_build "rtl"
printgr "MY-FLOPPY-DISTRO" "build completed"
cd ./../

exit 0

#
