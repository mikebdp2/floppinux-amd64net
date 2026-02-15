#!/usr/bin/env sh
#
#    floppinux_amd64net.sh: FLOPPINUX-AMD64NET build script, 15 Feb 2026.
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
        printf "\n${byellow}ERROR${bend}: object ${byellow}$1${bend} is not found !\n"
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

# Prints the current status message in '$1: $2' format with a green color highlighting of a '$1'.
printgr () {
    printf "${bgreen}$1${bend}: $2\n"
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

# Linux kernel
linux_build () {
    printgr "LINUX" "remove the old directory if it exists"
    rm -rf ./linux/
    printgr "LINUX" "git clone a repository"
    git clone --depth=1 --branch v6.18.10 "https://github.com/gregkh/linux.git"
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
    printgr "LINUX" "wget a .config file to configure the source code"
    wgetter "./linux.cfg" "https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/linux.cfg"
    mover "./linux.cfg" "./.config"
    printgr "LINUX" "build the source code"
    make ARCH="x86_64" bzImage -j$(nproc)
    printgr "LINUX" "print a size of a kernel"
    ls -al ./arch/x86_64/boot/bzImage
    cd ./../
    printgr "LINUX" "create a symbolic link"
    rm -f "./bzImage"
    ln -s "./linux/arch/x86_64/boot/bzImage" "./bzImage"
    return 0
}

# Dropbear SSH client and SCP utility
dropbear_build () {
    printgr "DROPBEAR" "remove the old directory if it exists"
    rm -rf ./dropbear/
    printgr "DROPBEAR" "git clone a repository"
    git clone --depth=1 --branch DROPBEAR_2025.89 "https://github.com/mkj/dropbear.git"
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
    printgr "LIBNL-TINY" "git clone a repository"
    git clone --depth=1 "https://github.com/openwrt/libnl-tiny.git"
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
    sudo make install
    cd ./../
    mover ./build/ ./build-rt/
    printgr "LIBNL-TINY" "patch to fix ucred structure for external usage by wpa_supplicant"
    wgetter "./libnl-tiny_ucred.patch" "https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/libnl-tiny_ucred.patch"
    cd ./../
    cd /usr/include/libnl-tiny/
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
    printgr "WPA" "git clone a repository"
    git clone --depth=1 --branch hostap_2_11 "https://github.com/mikebdp2/hostap.git"
    cd ./hostap/
    printgr "WPA:" "patch to fix linking with a libnl-tiny library"
    wgetter "./wpa_libnl.patch" "https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/wpa_libnl.patch"
    patch -p1 < ./wpa_libnl.patch
    printgr "WPA:" "wget a .config file to configure the source code"
    wgetter "./wpa.cfg" "https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/wpa.cfg"
    mover "./wpa.cfg" "./wpa_supplicant/.config"
    cd ./../
    printgr "WPA_SUPPLICANT" "remove the old directory if it exists"
    mover ./hostap/ ./wpa_supplicant/
    printgr "WPA_CLI" "remove the old directory if it exists"
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
    printgr "LINUX-FIRMWARE" "git clone a repository"
    git clone --depth=1 "https://github.com/mikebdp2/linux-firmware.git"
    return 0
}

# kirc simple IRC client
kirc_build () {
    printgr "KIRC" "remove the old directory if it exists"
    rm -rf ./kirc/
    printgr "KIRC" "git clone a repository"
    git clone --depth=1 --branch 1.2.2 "https://github.com/mcpcpc/kirc.git"
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
    printgr "BUSYBOX" "git clone a repository"
    git clone --depth=1 --branch 1_37_stable "https://github.com/mikebdp2/busybox.git"
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
    sudo rm -rf ./../filesystem/
    cp -r ./_install/ ./../filesystem
    cd ./../filesystem/
    printgr "BUSYBOX" "create the filesytem directories"
    mkdir -pv {dev,proc,etc/init.d,sys,tmp,home,var/run,lib/firmware/ath9k_htc,lib/firmware/rtl_nic}
    sudo mknod ./dev/console c 5 1
    sudo mknod ./dev/null c 1 3
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
udhcpc -i eth0 -q &
/usr/bin/setsid /bin/cttyhack /bin/sh
EOF
    chmod +x ./etc/init.d/rc
    printgr "BUSYBOX" "create the udhcpc script"
    rm -f  ./etc/udhcpc.sh
    cat >> ./etc/udhcpc.sh << EOF
#!/bin/sh
case "\$1" in
    bound|renew)
        # Apply the IP address and subnet mask
        ifconfig \$interface \$ip netmask \$subnet up
        
        # Set default gateway if provided
        if [ -n "\$router" ]; then
            # Remove any existing default route
            route del default 2>/dev/null
            # Add new default route (use first router if multiple)
            for gw in \$router; do
                route add default gw \$gw dev \$interface
                break
            done
        fi
        
        # Set DNS servers if provided
        if [ -n "\$dns" ]; then
            echo -n > /etc/resolv.conf
            for ns in \$dns; do
                echo "nameserver \$ns" >> /etc/resolv.conf
            done
        fi
        ;;
    deconfig)
        # Clear configuration when interface goes down
        ifconfig \$interface 0.0.0.0
        ;;
esac

exit 0
EOF
    chmod +x ./etc/udhcpc.sh
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
EOF
    chmod +x ./etc/get_repo.sh
    printgr "BUSYBOX" "copy the external files"
    cp ./../dropbear/dbclient ./usr/bin/dbclient
    cp ./../dropbear/scp ./usr/bin/scp
    cp ./../wpa_supplicant/wpa_supplicant/wpa_supplicant ./usr/bin/wpa_supplicant
    cp ./../wpa_cli/wpa_supplicant/wpa_cli ./usr/bin/wpa_cli
    cp ./../linux-firmware/ath9k_htc/htc_9271-1.4.0.fw ./lib/firmware/ath9k_htc/htc_9271-1.4.0.fw
    cp ./../linux-firmware/rtl_nic/rtl816* ./lib/firmware/rtl_nic/
    ### cp ./../kirc/kirc /usr/bin/kirc
    ### cp ./../kirc/kirc.txt /etc/kirc.txt
    cd ./usr/bin/
    ln -s ./dbclient ./ssh
    cd ./../../
    printgr "BUSYBOX" "give the ownership to root"
    sudo chown -R root:root ./
    printgr "BUSYBOX" "create a rootfs archive"
    rm -f ./../rootfs.cpio
    rm -f ./../rootfs.cpio.lzma
    find . -print0 | LC_ALL="C" sort -z | cpio -0 -H newc -o --reproducible 2>/dev/null > ./../rootfs.cpio
    strip-nondeterminism -t cpio -T 1770768000 ./../rootfs.cpio
    xz --threads=1 --format=lzma --check=crc32 --lzma1=dict=64MiB,lc=3,lp=0,pb=2,mode=normal,nice=273,mf=bt4,depth=0 < ./../rootfs.cpio > ./../rootfs.cpio.lzma
    rm -f ./../rootfs.cpio
    cd ./../
    printgr "BUSYBOX" "print a size of a rootfs archive"
    ls -al ./rootfs.cpio.lzma
    return 0
}

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

floppinux_build () {
    printgr "FLOPPINUX" "create a floppy"
    rm -f ./floppinux.img
    dd if=/dev/zero of=./floppinux.img bs=1k count=2880
    printgr "FLOPPINUX" "format a floppy"
    mkdosfs -n FLOPPINUX ./floppinux.img
    printgr "FLOPPINUX" "install a syslinux bootloader"
    syslinux --install ./floppinux.img
    printgr "FLOPPINUX" "mount a floppy"
    sudo rm -rf /temp_mnt
    sudo mkdir /temp_mnt
    sudo mount -o loop ./floppinux.img /temp_mnt
    df -B 1
    printgr "FLOPPINUX" "fill a floppy"
    printgr "FLOPPINUX" "copy a Linux kernel"
    ls -al ./bzImage
    sudo cp ./linux/arch/x86/boot/bzImage /temp_mnt
    df -B 1
    printgr "FLOPPINUX" "copy a rootfs filesystem"
    ls -al ./rootfs.cpio.lzma
    sudo cp ./rootfs.cpio.lzma /temp_mnt/rfscpiol.zma
    df -B 1
    printgr "FLOPPINUX" "copy a syslinux config file"
    sudo cp ./syslinux.cfg /temp_mnt
    df -B 1
    printgr "FLOPPINUX" "unmount a floppy"
    sudo umount /temp_mnt
    sudo rm -rf /temp_mnt
    printgr "FLOPPINUX" "print a sha256sum of a floppy"
    sha256sum ./floppinux.img
    return 0
}

commands_check
sudo ls
printgr "MY-FLOPPY-DISTRO" "remove the old directory if it exists"
sudo rm -rf /home/artix/my-floppy-distro/
mkdir /home/artix/my-floppy-distro/
cd /home/artix/my-floppy-distro/
printgr "MY-FLOPPY-DISTRO" "build started"
musl_get
linux_build
dropbear_build
libnl_build
wpa_build
firmware_get
kirc_build
busybox_build
syslinux_config
floppinux_build
printgr "MY-FLOPPY-DISTRO" "build completed"
cd ./../

exit 0
#
