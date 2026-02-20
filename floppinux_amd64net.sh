#!/usr/bin/env sh
#
#    floppinux_amd64net.sh: FLOPPINUX-AMD64NET build script, 16 Feb 2026.
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
# Reproducible builds
TOUCHER_ENABLED="1"
# Epoch value needs to have a lot of zeroes in a hexadecimal format, i.e. 1770094592
EPOCH_TIME="0"
TOUCH_TIME=$(date -u -d @$EPOCH_TIME +%Y%m%d%H%M.%S)
export SOURCE_DATE_EPOCH="$EPOCH_TIME"
# Timezone
export TZ="UTC"
# Locale
export LC_ALL="C"
export LANG="C"

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
    if [ ! -x "$( command -v $1 )" ] ; then
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
       ! command_exists "flex" "flex" || \
       ! command_exists "gcc" "gcc" || \
       ! command_exists "make" "make" || \
       ! command_exists "mcopy" "mtools" || \
       ! command_exists "mkdosfs" "dosfstools" || \
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
        encontinue
        return 1
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
        printf "\n${byellow}WARNING${bend}: cannot download a ${byellow}$1${bend} file !"
        printf "\n         Please check your Internet connection and try again.\n"
        return 1
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
    if [ "$TOUCHER_ENABLED" = "0" ]; then
        return 0
    fi
    if [ "$3" = "sudo" ]; then
        TZ="UTC" LC_ALL="C" LANG="C" find "$2" -print0 | sudo env TZ="UTC" LC_ALL="C" LANG="C" xargs -0 touch -h -t "$1" 2>/dev/null || true
    else
        TZ="UTC" LC_ALL="C" LANG="C" find "$2" -print0 |      env TZ="UTC" LC_ALL="C" LANG="C" xargs -0 touch -h -t "$1" 2>/dev/null || true
    fi
    return 0
}

# Changes the file '$2' modification time to '$1', also in a "sudo" mode if '$3' argument is set to "sudo".
toucher_file () {
    if [ "$TOUCHER_ENABLED" = "0" ]; then
        return 0
    fi
    if [ "$3" = "sudo" ]; then
        sudo env TZ="UTC" LC_ALL="C" LANG="C" touch -h -t "$1" "$2" 2>/dev/null
    else
                 TZ="UTC" LC_ALL="C" LANG="C" touch -h -t "$1" "$2" 2>/dev/null
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
                wgetter "./linux-$1.cfg" "https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/linux-$1.cfg"
                mover "./linux-$1.cfg" "./.config"
                printgr "LINUX-$1" "build the source code"
                    toucher_dir "$TOUCH_TIME" "./"
                make SOURCE_DATE_EPOCH="$EPOCH_TIME" TZ="UTC" LC_ALL="C" LANG="C" ARCH="x86_64" bzImage -j$(nproc)
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
        git clone --depth=1 --branch v6.18.10 "https://github.com/gregkh/linux.git"
        git_clone_check "./linux/"
    done
    cd ./linux/
    printgr "LINUX" "upgrade the source code to -Oz optimization level"
    mover ./.git/ ./../temp.git/ # Temporarily move ./.git/ to avoid damaging its contents in the process
    printgr "LINUX" "replace -O1 with -Oz optimization level..."
    find . -type f -print0 | xargs -0 sed -i -e "s/-O1/-Oz/g"
    printgr "LINUX" "replace -O2 with -Oz optimization level..."
    find . -type f -print0 | xargs -0 sed -i -e "s/-O2/-Oz/g"
    printgr "LINUX" "replace -O3 with -Oz optimization level..."
    find . -type f -print0 | xargs -0 sed -i -e "s/-O3/-Oz/g"
    printgr "LINUX" "replace -Os with -Oz optimization level..."
    find . -type f -print0 | xargs -0 sed -i -e "s/-Os/-Oz/g"
    mover ./../temp.git/ ./.git/
    git add .
    git commit -m "LINUX: upgrade the source code to -Oz optimization level"
    printgr "LINUX" "patch to disable the MICROCODE and NET_SELFTESTS configs"
    wgetter "./linux.patch" "https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/linux.patch"
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
    ./configure --host=x86_64-linux-musl --prefix=/usr --enable-static --disable-zlib --disable-syslog --disable-lastlog --disable-utmp --disable-utmpx --disable-wtmp --disable-wtmpx --disable-shadow --enable-bundled-libtom --disable-openpty --disable-loginfunc --disable-pututline --disable-pututxline --without-pam --disable-plugin CC='/home/artix/my-floppy-distro/x86_64-linux-musl-cross/bin/x86_64-linux-musl-gcc' \
    CFLAGS='-DDROPBEAR_ECDSA=0 -DDROPBEAR_ECDH=0 -static -Os -s -ffunction-sections -fdata-sections -fno-unwind-tables -fno-asynchronous-unwind-tables -fno-stack-protector -fomit-frame-pointer -fmerge-all-constants -fno-ident -fno-math-errno -fno-unroll-loops -ffast-math -fno-exceptions -march=x86-64 -mtune=generic -fno-align-functions -fno-align-jumps -fno-align-loops -fno-align-labels -fno-pie -I/home/artix/my-floppy-distro/x86_64-linux-musl-cross/include --sysroot=/home/artix/my-floppy-distro/x86_64-linux-musl-cross -fno-strict-aliasing' \
    LDFLAGS='-L/home/artix/my-floppy-distro/x86_64-linux-musl-cross/lib -L/home/artix/my-floppy-distro/x86_64-linux-musl-cross/x86_64-linux-musl/lib -static -s -Wl,--gc-sections -Wl,--strip-all -Wl,--build-id=none -Wl,-z,norelro -Wl,--hash-style=sysv -Wl,--no-eh-frame-hdr -Wl,-z,noseparate-code -Wl,--no-undefined-version -Wl,--as-needed -Wl,--sort-common -Wl,--sort-section=alignment -Wl,--compress-debug-sections=none -Wl,--warn-common -Wl,--discard-all -Wl,--discard-locals -Wl,--no-ld-generated-unwind-info -Wl,--orphan-handling=place -no-pie -L/home/artix/my-floppy-distro/x86_64-linux-musl-cross/lib --sysroot=/home/artix/my-floppy-distro/x86_64-linux-musl-cross'
    printgr "DROPBEAR" "build the source code"
    export CC="/home/artix/my-floppy-distro/x86_64-linux-musl-cross/bin/x86_64-linux-musl-gcc"
        toucher_dir "$TOUCH_TIME" "./"
    make SOURCE_DATE_EPOCH="$EPOCH_TIME" TZ="UTC" LC_ALL="C" LANG="C" ARCH="x86_64" CC="$CC" PROGRAMS="dbclient" dbclient scp -j$(nproc)
        toucher_dir "$TOUCH_TIME" "./"
    unset CC
    printgr "DROPBEAR" "sstrip the binaries"
    sstrip ./dbclient
        toucher_file "$TOUCH_TIME" "./dbclient"
    sstrip ./scp
        toucher_file "$TOUCH_TIME" "./scp"
    printgr "DROPBEAR" "create a symbolic link"
    rm -f "./ssh"
    ln -s "./dbclient" "./ssh"
    printgr "DROPBEAR" "print the sizes of binaries"
    ls -al ./dbclient
    ls -al ./scp
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
    printgr "LIBNL-TINY" "patch to setup the variables and fix ucred structure for libnl-tiny build"
    wgetter "./libnl-tiny.patch" "https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/libnl-tiny.patch"
    patch -p1 < ./libnl-tiny.patch
    rm -rf ./build/
    mkdir ./build/
    cd ./build/
    printgr "LIBNL-TINY" "configure the source code for toolchain directory installation"
    cmake -DCMAKE_INSTALL_PREFIX=/home/artix/my-floppy-distro/x86_64-linux-musl-cross/usr/ ..
    printgr "LIBNL-TINY" "build the source code"
        toucher_dir "$TOUCH_TIME" "./"
    make SOURCE_DATE_EPOCH="$EPOCH_TIME" TZ="UTC" LC_ALL="C" LANG="C" ARCH="x86_64" -j$(nproc)
        toucher_dir "$TOUCH_TIME" "./"
    printgr "LIBNL-TINY" "install the library to a toolchain directory"
    make SOURCE_DATE_EPOCH="$EPOCH_TIME" TZ="UTC" LC_ALL="C" LANG="C" ARCH="x86_64" install
    cd ./../
    mover ./build/ ./build-tc/
    mkdir ./build/
    cd ./build/
    printgr "LIBNL-TINY" "configure the source code for host OS directory installation"
    cmake -DCMAKE_INSTALL_PREFIX=/usr/ ..
    printgr "LIBNL-TINY" "build the source code"
        toucher_dir "$TOUCH_TIME" "./"
    make SOURCE_DATE_EPOCH="$EPOCH_TIME" TZ="UTC" LC_ALL="C" LANG="C" ARCH="x86_64" -j$(nproc)
        toucher_dir "$TOUCH_TIME" "./"
    printgr "LIBNL-TINY" "install the library to a host OS directory"
    sudoer "install the LIBNL-TINY library to a host OS directory"
    sudo make SOURCE_DATE_EPOCH="$EPOCH_TIME" TZ="UTC" LC_ALL="C" LANG="C" ARCH="x86_64" install
    cd ./../
    mover ./build/ ./build-rt/
    printgr "LIBNL-TINY" "patch to fix ucred structure for external usage by wpa_supplicant"
    wgetter "./libnl-tiny_ucred.patch" "https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/libnl-tiny_ucred.patch"
    cd /usr/include/libnl-tiny/
    sudoer "apply a LIBNL-TINY patch to fix ucred structure for external usage by wpa_supplicant"
    sudo patch -p1 < /home/artix/my-floppy-distro/libnl-tiny/libnl-tiny_ucred.patch
    cd /home/artix/my-floppy-distro/x86_64-linux-musl-cross/usr/include/libnl-tiny/
    patch -p1 < /home/artix/my-floppy-distro/libnl-tiny/libnl-tiny_ucred.patch
    cd /home/artix/my-floppy-distro/
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
    printgr "WPA:" "patch to fix linking with a libnl-tiny library"
    wgetter "./wpa_libnl.patch" "https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/wpa_libnl.patch"
    patch -p1 < ./wpa_libnl.patch
    printgr "WPA:" "wget a .config file to configure the source code"
    wgetter "./wpa.cfg" "https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/wpa.cfg"
    mover "./wpa.cfg" "./wpa_supplicant/.config"
    cd ./../
    printgr "WPA_SUPPLICANT" "remove the old directory if it exists and create a new directory"
    mover ./hostap/ ./wpa_supplicant/
    printgr "WPA_CLI" "remove the old directory if it exists and create a new directory"
    rm -rf ./wpa_cli/
    cp -r ./wpa_supplicant/ ./wpa_cli/
    cd ./wpa_supplicant/
    printgr "WPA_SUPPLICANT" "patch to setup the variables"
    wgetter "./wpa_supplicant.patch" "https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/wpa_supplicant.patch"
    patch -p1 < ./wpa_supplicant.patch
    cd ./wpa_supplicant/
    printgr "WPA_SUPPLICANT" "build the source code"
    export CC="/home/artix/my-floppy-distro/x86_64-linux-musl-cross/bin/x86_64-linux-musl-gcc"
        toucher_dir "$TOUCH_TIME" "./"
    make SOURCE_DATE_EPOCH="$EPOCH_TIME" TZ="UTC" LC_ALL="C" LANG="C" ARCH="x86_64" CC="$CC" wpa_supplicant -j$(nproc)
        toucher_dir "$TOUCH_TIME" "./"
    unset CC
    printgr "WPA_SUPPLICANT" "sstrip the binary"
    sstrip ./wpa_supplicant
        toucher_file "$TOUCH_TIME" "./wpa_supplicant"
    printgr "WPA_SUPPLICANT" "print a size of a binary"
    ls -al ./wpa_supplicant
    cd ./../../wpa_cli/
    printgr "WPA_CLI" "patch to setup the variables"
    wgetter "./wpa_cli.patch" "https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/wpa_cli.patch"
    patch -p1 < ./wpa_cli.patch
    cd ./wpa_supplicant/
    printgr "WPA_CLI" "build the source code"
    export CC="/home/artix/my-floppy-distro/x86_64-linux-musl-cross/bin/x86_64-linux-musl-gcc"
        toucher_dir "$TOUCH_TIME" "./"
    make SOURCE_DATE_EPOCH="$EPOCH_TIME" TZ="UTC" LC_ALL="C" LANG="C" ARCH="x86_64" CC="$CC" wpa_cli -j$(nproc)
        toucher_dir "$TOUCH_TIME" "./"
    unset CC
    printgr "WPA_CLI" "sstrip the binary"
    sstrip ./wpa_cli
        toucher_file "$TOUCH_TIME" "./wpa_cli"
    printgr "WPA_CLI" "print a size of a binary"
    ls -al ./wpa_cli
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
    wgetter "./kirc.patch" "https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/kirc.patch"
    patch -p1 < "./kirc.patch"
    export CC="/home/artix/my-floppy-distro/x86_64-linux-musl-cross/bin/x86_64-linux-musl-gcc"
    printgr "KIRC" "build the source code"
        toucher_dir "$TOUCH_TIME" "./"
    make SOURCE_DATE_EPOCH="$EPOCH_TIME" TZ="UTC" LC_ALL="C" LANG="C" ARCH="x86_64" CC="$CC" -j$(nproc)
        toucher_dir "$TOUCH_TIME" "./"
    unset CC
    printgr "KIRC" "sstrip a binary"
    sstrip ./kirc
        toucher_file "$TOUCH_TIME" "./kirc"
    printgr "KIRC" "print a size of a binary"
    ls -al ./kirc
    printgr "KIRC" "generate a user manual"
    man ./kirc.1 > ./kirc.txt
        toucher_file "$TOUCH_TIME" "./kirc.txt"
    cd ./../
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
    printgr "BUSYBOX" "upgrade the source code to -Oz optimization level"
    mover ./.git/ ./../temp.git/ # Temporarily move ./.git/ to avoid damaging its contents in the process
    printgr "BUSYBOX" "replace -O2 with -Oz optimization level..."
    find . -type f -print0 | xargs -0 sed -i -e "s/-O2/-Os/g"
    mover ./../temp.git/ ./.git/
    git add .
    git commit -m "BUSYBOX: upgrade the source code to -Oz optimization level"
    printgr "BUSYBOX" "fix for host OS like Arch/Artix Linux with GCC 14 or newer"
    sed -i "s/main() {}/int main() {}/" ./scripts/kconfig/lxdialog/check-lxdialog.sh
    printgr "BUSYBOX" "wget a .config file to configure the source code"
    wgetter "./busybox.cfg" "https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/busybox.cfg"
    mover "./busybox.cfg" "./.config"
    printgr "BUSYBOX" "setup the variables"
    sed -i "s|.*CONFIG_CROSS_COMPILER_PREFIX.*|CONFIG_CROSS_COMPILER_PREFIX=\"/home/artix/my-floppy-distro/x86_64-linux-musl-cross/bin/x86_64-linux-musl-\"|" ./.config
    sed -i "s|.*CONFIG_SYSROOT.*|CONFIG_SYSROOT=\"/home/artix/my-floppy-distro/x86_64-linux-musl-cross\"|" ./.config
    sed -i "s|.*CONFIG_EXTRA_CFLAGS.*|CONFIG_EXTRA_CFLAGS=\"-I/home/artix/my-floppy-distro/x86_64-linux-musl-cross/include -static -Os -s -ffunction-sections -fdata-sections -fno-unwind-tables -fno-asynchronous-unwind-tables -fno-stack-protector -fomit-frame-pointer -fmerge-all-constants -fno-ident -fno-math-errno -fno-unroll-loops -ffast-math -fvisibility=hidden -fno-exceptions -march=x86-64 -mtune=generic -fno-align-functions -fno-align-jumps -fno-align-loops -fno-align-labels -fno-pie\"|" ./.config
    sed -i "s|.*CONFIG_EXTRA_LDFLAGS.*|CONFIG_EXTRA_LDFLAGS=\"-L/home/artix/my-floppy-distro/x86_64-linux-musl-cross/lib -static -s -Wl,--gc-sections -Wl,--strip-all -Wl,--build-id=none -Wl,-z,norelro -Wl,--hash-style=sysv -Wl,--no-eh-frame-hdr -Wl,-z,noseparate-code -Wl,--no-undefined-version -Wl,--as-needed -Wl,--sort-common -Wl,--sort-section=alignment -Wl,--compress-debug-sections=none -Wl,--warn-common -Wl,--fatal-warnings -Wl,--discard-all -Wl,--discard-locals -Wl,--no-ld-generated-unwind-info -Wl,--orphan-handling=place -no-pie\"|" ./.config
    printgr "BUSYBOX" "build the source code"
        toucher_dir "$TOUCH_TIME" "./"
    make SOURCE_DATE_EPOCH="$EPOCH_TIME" TZ="UTC" LC_ALL="C" LANG="C" ARCH="x86_64" -j$(nproc)
    printgr "BUSYBOX" "sstrip a binary"
    sstrip ./busybox
    ls -al ./busybox
    printgr "BUSYBOX" "generate the initial filesystem"
    rm -rf ./_install/
    make SOURCE_DATE_EPOCH="$EPOCH_TIME" TZ="UTC" LC_ALL="C" LANG="C" ARCH="x86_64" install -j$(nproc)
        toucher_dir "$TOUCH_TIME" "./"
    rm -rf ./../filesystem/
    cp -r ./_install/ ./../filesystem/
    cd ./../filesystem/
        toucher_dir "$TOUCH_TIME" "./"
    printgr "BUSYBOX" "create the filesystem directories"
    mkdir -p {./dev/,./proc/,./etc/init.d/,./sys/,./tmp/,./home/,./var/run/,./lib/firmware/ath9k_htc/}
        toucher_dir "$TOUCH_TIME" "./"
    printgr "BUSYBOX" "wget a welcome message"
    ### wgetter "./welcome" "https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/welcome"
    ###     toucher_file "$TOUCH_TIME" "./welcome"
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
    printgr "BUSYBOX" "create the init rc script"
    rm -f  ./etc/init.d/rc
    cat >> ./etc/init.d/rc << EOF
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mdev -s
ln -s /proc/mounts /etc/mtab
mkdir -p /mnt /home
mount -t msdos -o rw /dev/fd0 /mnt
mkdir -p /mnt/data
mount --bind /mnt/data /home
clear
cat ./welcome
cd /home/
mdev -d &

clear_iface() {
 local iface=\$1
 [ -z "\$iface" ] && return 1
 ifconfig "\$iface" down 2>/dev/null
 # Parse route table
 route -n 2>/dev/null | while read dest gw mask flags metric ref use curiface; do
  # Skip headers
  case "\$dest" in "Destination"|"Kernel"*|"") continue ;; esac
   # Route belongs to our iface?
  [ "\$curiface" = "\$iface" ] || continue
  if [ "\$dest" = "0.0.0.0" ]; then
   # Del default route
   route del default dev "\$iface" 2>/dev/null
  else
   # Setup route, only if dest~=IP
   case "\$dest" in *.*.*.*)
    route del -net "\$dest" netmask "\$mask" dev "\$iface" 2>/dev/null
   ;; esac
  fi
 done
 ifconfig "\$iface" down 2>/dev/null
 ifconfig "\$iface" 0.0.0.0 2>/dev/null
}

monitor_link() {
 local iface=\$1 last_status=""
 local carrier_file="/sys/class/net/\$iface/carrier"
 [ -z "\$iface" ] && return 1
 while true; do
  [ ! -d "/sys/class/net/\$iface" ] && break
  [ -f "\$carrier_file" ] || { sleep 1; continue; }
  current_status=\$(cat "\$carrier_file" 2>/dev/null) || { sleep 1; continue; }
  [ -n "\$current_status" ] || { sleep 1; continue; }
  [ "\$current_status" = "\$last_status" ] && { sleep 1; continue; }
  case "\$current_status" in
   1*)
    echo "  Link detected on \$iface"
    # Check if any udhcpc already running for this interface
    udhcpc_running=""
    for p in /proc/[0-9]*; do
     if [ -r "\$p/cmdline" ]; then
      cmdline=\$(cat "\$p/cmdline" 2>/dev/null)
      case "\$cmdline" in *udhcpc*"-i \$iface"*) udhcpc_running="yes"; break;; esac
     fi
    done
    # Start udhcpc if not running
    [ -z "\$udhcpc_running" ] && udhcpc -i "\$iface" -s /etc/udhcpc.sh -b >/dev/null 2>&1 &
   ;;
   0*)
    echo "  Link lost on \$iface"
    # Kill ALL udhcpc processes for this interface by matching cmdline
    for p in /proc/[0-9]*; do
     if [ -r "\$p/cmdline" ]; then
      cmdline=\$(cat "\$p/cmdline" 2>/dev/null)
      case "\$cmdline" in *udhcpc*"-i \$iface"*)
       kill -9 "\${p##*/}" 2>/dev/null
      ;; esac
     fi
    done
    clear_iface "\$iface"
   ;;
  esac
  last_status="\$current_status"
  sleep 1
 done
}

monitor_wireless_hotplug() {
 local wireless_handled_dir="/var/run/wireless-handled"
 mkdir -p "\$wireless_handled_dir" 2>/dev/null
 echo "Start WiFi hotplug monitor..."
 while true; do
  for netdev in /sys/class/net/wlan*; do
   [ -e "\$netdev" ] || continue
   netdev=\${netdev##*/}
   # Handled Y/N?
   [ -f "\$wireless_handled_dir/\$netdev" ] && continue
   echo "  New WiFi dev detected: \$netdev"
   echo "handled" > "\$wireless_handled_dir/\$netdev"
   ifconfig \$netdev up 2>/dev/null
   [ -f /etc/wpa_supplicant.conf ] && wpa_supplicant -B -i \$netdev -c /etc/wpa_supplicant.conf
   if [ -f "/sys/class/net/\$netdev/carrier" ] && [ "\$(cat "/sys/class/net/\$netdev/carrier" 2>/dev/null)" = "1" ]; then
    udhcpc -i \$netdev -s /etc/udhcpc.sh -b >/dev/null 2>&1 &
   fi
   monitor_link \$netdev &
  done
  sleep 3
 done
}

echo "Start udhcpc& on all netdevs..."
for netdev in /sys/class/net/*; do
 netdev=\${netdev##*/}
 [ "\$netdev" = "lo" ] && continue
 echo "  Start udhcpc on: \$netdev"
 ifconfig \$netdev up 2>/dev/null
 udhcpc -i \$netdev -s /etc/udhcpc.sh -b >/dev/null 2>&1 &
 monitor_link \$netdev &
 case \$netdev in wlan*)
  echo "  Start wpa_supplicant on: \$netdev"
  wpa_supplicant -B -i \$netdev -c /etc/wpa_supplicant.conf
 ;; esac
done
monitor_wireless_hotplug &
echo -e "udhcpc& autosetup their ifaces when: Eth plugged / WiFi connects (+ USB hotplug)\n\nManual WiFi (kill old proc 1st):\n  wpa_supplicant -B -i wlanXXX -c /etc/wpa_supplicant.conf ; wpa_cli -i wlanXXX :\n  scan, scan_results, add_network, scan, scan_results, add_network (prints N num),\n  set_network N ssid \"NAME\", set_network N psk \"PASS\", enable_network N,\n  save_config, quit ; udhcpc -i wlanXXX -s /etc/udhcpc.sh -b &"
/usr/bin/setsid /bin/cttyhack /bin/sh
EOF
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
wget "https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/repo.sh"
chmod +x ./repo.sh
./repo.sh
EOF
    chmod +x ./etc/get_repo.sh
        toucher_file "$TOUCH_TIME" "./etc/get_repo.sh"
    printgr "BUSYBOX" "create the udhcpc script"
    rm -f  ./etc/udhcpc.sh
    cat >> ./etc/udhcpc.sh << EOF
#!/bin/sh
case "\$1" in
 "bound"|"renew")
  # Set IP/subnet
  ifconfig \$interface \$ip netmask \$subnet up
  # Set gateway if provided
  if [ -n "\$router" ]; then
   # Remove existing default routes
   while route del default 2>/dev/null; do :; done
   # Add new default route (1st router if multiple)
   for gw in \$router; do
    route add default gw \$gw dev \$interface
    break
   done
  fi
  # Set DNS if provided
  if [ -n "\$dns" ]; then
   # Atomic write all DNS
   { for ns in \$dns; do echo "nameserver \$ns"; done; echo; } > /etc/resolv.conf
   fi
  ;;
  "deconfig")
   # Lease expired? Clear IP
   ifconfig \$interface 0.0.0.0
   ;;
  "leasefail")
   echo "  DHCP lease failed on \$interface"
  ;;
  *)
   echo "udhcpc unsupported case \$1"
   ;;
esac
exit 0
EOF
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
    ln -s ./dbclient ./ssh
        toucher_file "$TOUCH_TIME" "./ssh"
    cd ./../../../
        toucher_dir "$TOUCH_TIME" "./filesystem/"
    printgr "BUSYBOX-NORTL" "create a directory"
    if [ -d "./filesystem-nortl/" ] ; then
        sudoer "remove the old /home/artix/my-floppy-distro/filesystem-nortl/ directory"
        sudo rm -rf ./filesystem-nortl/
    fi
    cp -r ./filesystem/ ./filesystem-nortl/
    cd ./filesystem-nortl/
        toucher_dir "$TOUCH_TIME" "./"
    printgr "BUSYBOX-NORTL" "create the device nodes"
    sudoer "create the device nodes for BUSYBOX-NORTL"
    sudo mknod ./dev/console c 5 1
    sudo mknod ./dev/null c 1 3
        toucher_dir "$TOUCH_TIME" "./" "sudo"
    printgr "BUSYBOX-NORTL" "give the ownership to root"
    sudoer "give the ownership to root for BUSYBOX-NORTL"
    sudo chown -R root:root ./
    printgr "BUSYBOX-NORTL" "change the files/dirs modification time"
    sudoer "change the files/dirs modification time"
        toucher_dir "$TOUCH_TIME" "./" "sudo"
    printgr "BUSYBOX-NORTL" "create a rootfs archive"
    rm -f ./../rootfs-nortl.cpio
    rm -f ./../rootfs-nortl.cpio.lzma
    LC_ALL="C" LANG="C" find . -print0 | LC_ALL="C" LANG="C" sort -z | cpio -0 -H newc -o --reproducible 2>/dev/null > ./../rootfs-nortl.cpio
        toucher_file "$TOUCH_TIME" "./../rootfs-nortl.cpio"
    strip-nondeterminism -t cpio -T $EPOCH_TIME ./../rootfs-nortl.cpio
        toucher_file "$TOUCH_TIME" "./../rootfs-nortl.cpio"
    xz --threads=1 --format=lzma --check=crc32 --lzma1=dict=64MiB,lc=3,lp=0,pb=2,mode=normal,nice=273,mf=bt4,depth=0 < ./../rootfs-nortl.cpio > ./../rootfs-nortl.cpio.lzma
        toucher_file "$TOUCH_TIME" "./../rootfs-nortl.cpio.lzma"
    cd ./../
    printgr "BUSYBOX-NORTL" "print a size of a rootfs archive"
    ls -al ./rootfs-nortl.cpio.lzma
    printgr "BUSYBOX-NORTL" "create the symbolic links"
    rm -f "./rootfs-ath.cpio.lzma"
    ln -s "./rootfs-nortl.cpio.lzma" "./rootfs-ath.cpio.lzma"
        toucher_file "$TOUCH_TIME" "./rootfs-ath.cpio.lzma"
    rm -f "./rootfs-pcn.cpio.lzma"
    ln -s "./rootfs-nortl.cpio.lzma" "./rootfs-pcn.cpio.lzma"
        toucher_file "$TOUCH_TIME" "./rootfs-pcn.cpio.lzma"
    printgr "BUSYBOX-WIRTL" "create a directory"
    if [ -d "./filesystem-wirtl/" ] ; then
        sudoer "remove the old /home/artix/my-floppy-distro/filesystem-wirtl/ directory"
        sudo rm -rf ./filesystem-wirtl/
    fi
    cp -r ./filesystem/ ./filesystem-wirtl/
    cd ./filesystem-wirtl/
        toucher_dir "$TOUCH_TIME" "./"
    printgr "BUSYBOX-WIRTL" "create the device nodes"
    sudoer "create the device nodes for BUSYBOX-WIRTL"
    sudo mknod ./dev/console c 5 1
    sudo mknod ./dev/null c 1 3
        toucher_dir "$TOUCH_TIME" "./" "sudo"
    printgr "BUSYBOX-WIRTL" "copy the Realtek firmware files"
    mkdir -p ./lib/firmware/rtl_nic/
    LC_ALL="C" LANG="C" find ./../linux-firmware/rtl_nic/ -name "rtl816*" | \
        LC_ALL="C" LANG="C" sort | while IFS= read -r file; do \
            cp "$file" ./lib/firmware/rtl_nic/; \
            toucher_dir "$TOUCH_TIME" "./lib/firmware/rtl_nic/"; \
        done
    printgr "BUSYBOX-WIRTL" "give the ownership to root"
    sudoer "give the ownership to root for BUSYBOX-WIRTL"
    sudo chown -R root:root ./
    printgr "BUSYBOX-WIRTL" "change the files/dirs modification time"
    sudoer "change the files/dirs modification time"
        toucher_dir "$TOUCH_TIME" "./" "sudo"
    printgr "BUSYBOX-WIRTL" "create a rootfs archive"
    rm -f ./../rootfs-wirtl.cpio
    rm -f ./../rootfs-wirtl.cpio.lzma
    LC_ALL="C" LANG="C" find . -print0 | LC_ALL="C" LANG="C" sort -z | cpio -0 -H newc -o --reproducible 2>/dev/null > ./../rootfs-wirtl.cpio
        toucher_file "$TOUCH_TIME" "./../rootfs-wirtl.cpio"
    strip-nondeterminism -t cpio -T $EPOCH_TIME ./../rootfs-wirtl.cpio
        toucher_file "$TOUCH_TIME" "./../rootfs-wirtl.cpio"
    xz --threads=1 --format=lzma --check=crc32 --lzma1=dict=64MiB,lc=3,lp=0,pb=2,mode=normal,nice=273,mf=bt4,depth=0 < ./../rootfs-wirtl.cpio > ./../rootfs-wirtl.cpio.lzma
        toucher_file "$TOUCH_TIME" "./../rootfs-wirtl.cpio.lzma"
    cd ./../
    printgr "BUSYBOX-WIRTL" "print a size of a rootfs archive"
    ls -al ./rootfs-wirtl.cpio.lzma
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
                printgr "FLOPPINUX-$1" "format a floppy"
                mkdosfs -n FLOPPINUX ./flpnx$1.img
                printgr "FLOPPINUX-$1" "install a syslinux bootloader"
                syslinux --install ./flpnx$1.img
                printgr "FLOPPINUX-$1" "re-create a /temp_mnt mount point"
                if [ -d "/temp_mnt" ] ; then
                    sudoer "remove a /temp_mnt mount point"
                    sudo rm -rf /temp_mnt
                fi
                sudoer "create a /temp_mnt mount point"
                sudo mkdir /temp_mnt
                printgr "FLOPPINUX-$1" "mount a floppy"
                sudoer "mount a ./flpnx$1.img floppy"
                sudo mount -o loop ./flpnx$1.img /temp_mnt
                df -B 1
                printgr "FLOPPINUX-$1" "fill a floppy"
                printgr "FLOPPINUX-$1" "copy a Linux kernel"
                ls -alL ./bzImage-$1
                sudoer "copy a Linux kernel to ./flpnx$1.img"
                sudo cp ./bzImage-$1 /temp_mnt/bzImage
                df -B 1
                printgr "FLOPPINUX-$1" "copy a rootfs filesystem"
                ls -alL ./rootfs-$1.cpio.lzma
                sudoer "copy a rootfs filesystem to ./flpnx$1.img"
                sudo cp ./rootfs-$1.cpio.lzma /temp_mnt/rfscpiol.zma
                df -B 1
                printgr "FLOPPINUX-$1" "copy a syslinux config file"
                sudoer "copy a syslinux config file to ./flpnx$1.img"
                sudo cp ./syslinux.cfg /temp_mnt
                df -B 1
                printgr "FLOPPINUX-$1" "change the files/dirs modification time"
                cd /temp_mnt
                sudoer "change the files/dirs modification time"
                    toucher_dir "$TOUCH_TIME" "./" "sudo"
                cd /home/artix/my-floppy-distro/
                printgr "FLOPPINUX-$1" "unmount a floppy"
                sudoer "unmount a ./flpnx$1.img floppy"
                sudo umount /temp_mnt
                sudoer "remove a /temp_mnt mount point"
                sudo rm -rf /temp_mnt
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
    while [ ! -f "/home/artix/temp.sudo" ] ; do
        sudo touch /home/artix/temp.sudo
    done
    sudo rm -f /home/artix/temp.sudo
}

commands_check
printgr "MY-FLOPPY-DISTRO" "build started"
if [ -d "/home/artix/my-floppy-distro/" ] ; then
    sudoer "remove the old /home/artix/my-floppy-distro/ directory"
    sudo rm -rf /home/artix/my-floppy-distro/
fi
mkdir /home/artix/my-floppy-distro/
cd /home/artix/my-floppy-distro/
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
