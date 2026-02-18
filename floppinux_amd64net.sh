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
                make ARCH="x86_64" bzImage -j$(nproc)
                printgr "LINUX-$1" "print a size of a kernel"
                ls -al ./arch/x86_64/boot/bzImage
                cd ./../
                printgr "LINUX-$1" "create a symbolic link"
                rm -f "./bzImage-$1"
                ln -s "./linux-$1/arch/x86_64/boot/bzImage" "./bzImage-$1"
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
    make CC="$CC" PROGRAMS="dbclient" dbclient scp -j$(nproc)
    unset CC
    printgr "DROPBEAR" "sstrip the binaries"
    sstrip ./dbclient
    sstrip ./scp
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
    make -j$(nproc)
    printgr "LIBNL-TINY" "install the library to a toolchain directory"
    make install
    cd ./../
    mover ./build/ ./build-tc/
    mkdir ./build/
    cd ./build/
    printgr "LIBNL-TINY" "configure the source code for host OS directory installation"
    cmake -DCMAKE_INSTALL_PREFIX=/usr/ ..
    printgr "LIBNL-TINY" "build the source code"
    make -j$(nproc)
    printgr "LIBNL-TINY" "install the library to a host OS directory"
    sudoer "install the LIBNL-TINY library to a host OS directory"
    sudo make install
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
    make clean
    make CC="$CC" wpa_supplicant -j$(nproc)
    unset CC
    printgr "WPA_SUPPLICANT" "sstrip the binary"
    sstrip ./wpa_supplicant
    printgr "WPA_SUPPLICANT" "print a size of a binary"
    ls -al ./wpa_supplicant
    cd ./../../wpa_cli/
    printgr "WPA_CLI" "patch to setup the variables"
    wgetter "./wpa_cli.patch" "https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/wpa_cli.patch"
    patch -p1 < ./wpa_cli.patch
    cd ./wpa_supplicant/
    printgr "WPA_CLI" "build the source code"
    export CC="/home/artix/my-floppy-distro/x86_64-linux-musl-cross/bin/x86_64-linux-musl-gcc"
    make clean
    make CC="$CC" wpa_cli -j$(nproc)
    unset CC
    printgr "WPA_CLI" "sstrip the binary"
    sstrip ./wpa_cli
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
    make clean
    make CC="$CC" -j$(nproc)
    unset CC
    printgr "KIRC" "sstrip a binary"
    sstrip ./kirc
    printgr "KIRC" "print a size of a binary"
    ls -al ./kirc
    printgr "KIRC" "generate a user manual"
    man ./kirc.1 > ./kirc.txt
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
    make ARCH="x86_64" clean
    make ARCH="x86_64" -j$(nproc)
    printgr "BUSYBOX" "sstrip a binary"
    sstrip ./busybox
    ls -al ./busybox
    printgr "BUSYBOX" "generate the initial filesystem"
    rm -rf ./_install/
    make ARCH="x86_64" install
    rm -rf ./../filesystem/
    cp -r ./_install/ ./../filesystem/
    cd ./../filesystem/
    printgr "BUSYBOX" "create the filesytem directories"
    mkdir -p {./dev/,./proc/,./etc/init.d/,./sys/,./tmp/,./home/,./var/run/,./lib/firmware/ath9k_htc/}
    printgr "BUSYBOX" "wget a welcome message"
    wgetter "./welcome" "https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/welcome"
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
# The simplest approach - run DHCP on everything except loopback
echo "Starting DHCP clients on all network interfaces..."
for netdev in \$(ls /sys/class/net/) ; do
    if [ "\$netdev" != "lo" ]; then
        echo "    Starting DHCP client on: \$netdev"
        # Bring interface up (ignore errors for virtual interfaces)
        ifconfig \$netdev up 2>/dev/null
        # Start DHCP - will work when connectivity becomes available
        udhcpc -i \$netdev -s /etc/udhcpc.sh -b > /dev/null 2>&1 &
    fi
done
echo "udhcpc DHCP clients are running in the background, and will autoconfig their interfaces when:"
echo "- Ethernet cable is plugged in"
echo "- PCIe WiFi associates with an access point"
echo "But for WiFi USB after wpa_supplicant/wpa_cli setup - you will have to run:"
echo "    udhcpc -i wlanXXX -s /etc/udhcpc.sh -b > /dev/null 2>&1 &"
echo "    wpa_supplicant -B -i wlanXXX -c /etc/wpa_supplicant.conf"
echo "    wpa_cli"
echo "    scan, scan_results, add_network, set_network 0 ssid \"NetworkName\""
echo "    set_network 0 psk \"Password\", enable_network 0, save_config, quit"
/usr/bin/setsid /bin/cttyhack /bin/sh
EOF
    chmod +x ./etc/init.d/rc
    printgr "BUSYBOX" "create the wpa_supplicant config"
    rm -f  ./etc/wpa_supplicant.conf
    cat >> ./etc/wpa_supplicant.conf << EOF
ctrl_interface=/var/run/wpa_supplicant
update_config=1
EOF
    printgr "BUSYBOX" "create the get_repo.sh script"
    rm -f  ./etc/get_repo.sh
    cat >> ./etc/get_repo.sh << EOF
wget "https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/repo.sh"
chmod +x ./repo.sh
./repo.sh
EOF
    chmod +x ./etc/get_repo.sh
    printgr "BUSYBOX" "create the udhcpc script"
    rm -f  ./etc/udhcpc.sh
    cat >> ./etc/udhcpc.sh << EOF
#!/bin/sh
case "\$1" in
    "bound"|"renew")
        # Apply the IP address and subnet mask
        ifconfig \$interface \$ip netmask \$subnet up
        
        # Set default gateway if provided
        if [ -n "\$router" ] ; then
            # Remove any existing default route
            while route del default 2>/dev/null; do :; done
            # Add new default route (use first router if multiple)
            for gw in \$router; do
                route add default gw \$gw dev \$interface
                break
            done
        fi
        
        # Set DNS servers if provided
        if [ -n "\$dns" ] ; then
            # Write all DNS servers at once (atomic)
            {
                for ns in \$dns; do
                    echo "nameserver \$ns"
                done
                echo  # Ensure trailing newline
            } > /etc/resolv.conf
        fi
        ;;
    "deconfig")
        # Clear configuration when interface goes down
        ifconfig \$interface 0.0.0.0
        ;;
    *)
        echo "udhcpc unsupported case \$1"
        ;;
esac

exit 0
EOF
    chmod +x ./etc/udhcpc.sh
    printgr "BUSYBOX" "copy the external files"
    cp ./../dropbear/dbclient ./usr/bin/dbclient
    cp ./../dropbear/scp ./usr/bin/scp
    cp ./../wpa_supplicant/wpa_supplicant/wpa_supplicant ./usr/bin/wpa_supplicant
    cp ./../wpa_cli/wpa_supplicant/wpa_cli ./usr/bin/wpa_cli
    cp ./../linux-firmware/ath9k_htc/htc_9271-1.4.0.fw ./lib/firmware/ath9k_htc/htc_9271-1.4.0.fw
    ### cp ./../kirc/kirc /usr/bin/kirc
    ### cp ./../kirc/kirc.txt /etc/kirc.txt
    cd ./usr/bin/
    ln -s ./dbclient ./ssh
    cd ./../../../
    printgr "BUSYBOX-NORTL" "create a directory"
    if [ -d "./filesystem-nortl/" ] ; then
        sudoer "remove the old /home/artix/my-floppy-distro/filesystem-nortl/ directory"
        sudo rm -rf ./filesystem-nortl/
    fi
    cp -r ./filesystem/ ./filesystem-nortl/
    cd ./filesystem-nortl/
    printgr "BUSYBOX-NORTL" "create the device nodes"
    sudoer "create the device nodes for BUSYBOX-NORTL"
    sudo mknod ./dev/console c 5 1
    sudo mknod ./dev/null c 1 3
    printgr "BUSYBOX-NORTL" "give the ownership to root"
    sudoer "give the ownership to root for BUSYBOX-NORTL"
    sudo chown -R root:root ./
    printgr "BUSYBOX-NORTL" "create a rootfs archive"
    rm -f ./../rootfs-nortl.cpio
    rm -f ./../rootfs-nortl.cpio.lzma
    find . -print0 | LC_ALL="C" sort -z | cpio -0 -H newc -o --reproducible 2>/dev/null > ./../rootfs-nortl.cpio
    strip-nondeterminism -t cpio -T 1770768000 ./../rootfs-nortl.cpio
    xz --threads=1 --format=lzma --check=crc32 --lzma1=dict=64MiB,lc=3,lp=0,pb=2,mode=normal,nice=273,mf=bt4,depth=0 < ./../rootfs-nortl.cpio > ./../rootfs-nortl.cpio.lzma
    rm -f ./../rootfs-nortl.cpio
    cd ./../
    printgr "BUSYBOX-NORTL" "print a size of a rootfs archive"
    ls -al ./rootfs-nortl.cpio.lzma
    printgr "BUSYBOX-NORTL" "create the symbolic links"
    rm -f "./rootfs-ath.cpio.lzma"
    ln -s "./rootfs-nortl.cpio.lzma" "./rootfs-ath.cpio.lzma"
    rm -f "./rootfs-pcn.cpio.lzma"
    ln -s "./rootfs-nortl.cpio.lzma" "./rootfs-pcn.cpio.lzma"
    printgr "BUSYBOX-WIRTL" "create a directory"
    if [ -d "./filesystem-wirtl/" ] ; then
        sudoer "remove the old /home/artix/my-floppy-distro/filesystem-wirtl/ directory"
        sudo rm -rf ./filesystem-wirtl/
    fi
    cp -r ./filesystem/ ./filesystem-wirtl/
    cd ./filesystem-wirtl/
    printgr "BUSYBOX-WIRTL" "create the device nodes"
    sudoer "create the device nodes for BUSYBOX-WIRTL"
    sudo mknod ./dev/console c 5 1
    sudo mknod ./dev/null c 1 3
    printgr "BUSYBOX-WIRTL" "copy the Realtek firmware files"
    mkdir -p ./lib/firmware/rtl_nic/
    cp ./../linux-firmware/rtl_nic/rtl816* ./lib/firmware/rtl_nic/
    printgr "BUSYBOX-WIRTL" "give the ownership to root"
    sudoer "give the ownership to root for BUSYBOX-WIRTL"
    sudo chown -R root:root ./
    printgr "BUSYBOX-WIRTL" "create a rootfs archive"
    rm -f ./../rootfs-wirtl.cpio
    rm -f ./../rootfs-wirtl.cpio.lzma
    find . -print0 | LC_ALL="C" sort -z | cpio -0 -H newc -o --reproducible 2>/dev/null > ./../rootfs-wirtl.cpio
    strip-nondeterminism -t cpio -T 1770768000 ./../rootfs-wirtl.cpio
    xz --threads=1 --format=lzma --check=crc32 --lzma1=dict=64MiB,lc=3,lp=0,pb=2,mode=normal,nice=273,mf=bt4,depth=0 < ./../rootfs-wirtl.cpio > ./../rootfs-wirtl.cpio.lzma
    rm -f ./../rootfs-wirtl.cpio
    cd ./../
    printgr "BUSYBOX-WIRTL" "print a size of a rootfs archive"
    ls -al ./rootfs-wirtl.cpio.lzma
    printgr "BUSYBOX-WIRTL" "create a symbolic link"
    rm -f "./rootfs-rtl.cpio.lzma"
    ln -s "./rootfs-wirtl.cpio.lzma" "./rootfs-rtl.cpio.lzma"
    return 0
}

# Generate the syslinux configs
syslinux_config() {
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
