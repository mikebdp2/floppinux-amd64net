#!/usr/bin/env sh
#
#    floppinux_amd64net.sh: FLOPPINUX-AMD64NET build script, 13 Feb 2026.
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

# Checks if a command '$1' exists.
command_exists () {
    if [ ! -x "$( command -v $1 )" ] ; then
        printf "\n${bred}ERROR${bend}: command ${bold}$1${bend} is not found !\n"
        printf "       Please install ${bgreen}$2${bend} if you are on Artix Linux\n"
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
        printf "\n${byellow}WARNING${bend}: file ${bold}$1${bend} is not found !\n"
        return 1
    else
        return 0
    fi
}

# Force removes a file '$2' and then moves a file '$1' to '$2'.
mover () {
    if file_exists "$1" ; then
        rm -f "$2"
        mv "$1" "$2"
        return 0
    else
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
        printf "\n${byellow}WARNING${bend}: cannot download a ${bold}$1${bend} file !"
        printf "\n         Please check your Internet connection and try again.\n"
        return 1
    else
        sleep 1
        return 0
    fi
}

# MUSL toolchain
musl_get () {
    printf "MUSL: remove the old directory if it exists\n"
    rm -rf ./x86_64-linux-musl-cross/
    printf "MUSL: wget the archive with a toolchain\n"
    wgetter "./x86_64-linux-musl-cross.tgz" "https://musl.cc/x86_64-linux-musl-cross.tgz"
    tar -xvf ./x86_64-linux-musl-cross.tgz
}

# Linux kernel
linux_build () {
    printf "LINUX: remove the old directory if it exists\n"
    rm -rf ./linux/
    git clone --depth=1 --branch v6.18.10 "https://github.com/gregkh/linux.git"
    cd ./linux/
    printf "LINUX: upgrade the source code to -Oz optimization level\n"
    rm -rf ./../temp.git/
    mv ./.git/ ./../temp.git/ # Temporarily move ./.git/ to avoid damaging its contents in the process
    printf "LINUX: replace -O1 with -Oz optimization level...\n"
    find . -type f -print0 | xargs -0 sed -i -e "s/-O1/-Oz/g"
    printf "LINUX: replace -O2 with -Oz optimization level...\n"
    find . -type f -print0 | xargs -0 sed -i -e "s/-O2/-Oz/g"
    printf "LINUX: replace -O3 with -Oz optimization level...\n"
    find . -type f -print0 | xargs -0 sed -i -e "s/-O3/-Oz/g"
    printf "LINUX: replace -Os with -Oz optimization level...\n"
    find . -type f -print0 | xargs -0 sed -i -e "s/-Os/-Oz/g"
    mv ./../temp.git/ ./.git/
    git add .
    git commit -m "LINUX: upgrade the source code to -Oz optimization level"
    printf "LINUX: patch to disable the MICROCODE and NET_SELFTESTS configs\n"
    wgetter "./linux.patch" "https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/linux.patch"
    patch -p1 < ./linux.patch
    git add ./arch/x86/Kconfig
    git add ./net/Kconfig
    git commit -m "LINUX: disable the MICROCODE and NET_SELFTESTS configs"
    printf "LINUX: wget a .config file to configure the source code\n"
    wgetter "./linux.cfg" "https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/linux.cfg"
    mover "./linux.cfg" "./.config"
    make ARCH="x86_64" clean
    make ARCH="x86_64" bzImage -j$(nproc)
    ls -al ./arch/x86_64/boot/bzImage
    cp ./arch/x86_64/boot/bzImage ./../bzImage
    cd ./../
}

# Dropbear SSH client and SCP utility
dropbear_build () {
    printf "DROPBEAR: remove the old directory if it exists\n"
    rm -rf ./dropbear/
    printf "DROPBEAR: git clone a repository\n"
    git clone --depth=1 --branch DROPBEAR_2025.89 "https://github.com/mkj/dropbear.git"
    cd ./dropbear/
    make clean
    make distclean
    export CC="/home/artix/my-floppy-distro/x86_64-linux-musl-cross/bin/x86_64-linux-musl-gcc"
    printf "DROPBEAR: configure the source code\n"
    ./configure --host=x86_64-linux-musl --prefix=/usr --enable-static --disable-zlib --disable-syslog --disable-lastlog --disable-utmp --disable-utmpx --disable-wtmp --disable-wtmpx --disable-shadow --enable-bundled-libtom --disable-openpty --disable-loginfunc --disable-pututline --disable-pututxline --without-pam --disable-plugin CC='/home/artix/my-floppy-distro/x86_64-linux-musl-cross/bin/x86_64-linux-musl-gcc' \
    CFLAGS='-DDROPBEAR_ECDSA=0 -DDROPBEAR_ECDH=0 -static -Os -s -ffunction-sections -fdata-sections -fno-unwind-tables -fno-asynchronous-unwind-tables -fno-stack-protector -fomit-frame-pointer -fmerge-all-constants -fno-ident -fno-math-errno -fno-unroll-loops -ffast-math -fno-plt -fno-exceptions -march=x86-64 -mtune=generic -fno-align-functions -fno-align-jumps -fno-align-loops -fno-align-labels -I/home/artix/my-floppy-distro/x86_64-linux-musl-cross/include --sysroot=/home/artix/my-floppy-distro/x86_64-linux-musl-cross' \
    LDFLAGS='-L/home/artix/my-floppy-distro/x86_64-linux-musl-cross/lib -L/home/artix/my-floppy-distro/x86_64-linux-musl-cross/x86_64-linux-musl/lib -static -s -Wl,--gc-sections -Wl,--strip-all -Wl,--build-id=none -Wl,-z,norelro -Wl,--hash-style=sysv -Wl,--no-eh-frame-hdr -Wl,-z,noseparate-code -Wl,--no-undefined-version -Wl,--as-needed -Wl,--sort-common -Wl,--sort-section=alignment -Wl,--compress-debug-sections=none -Wl,--warn-common -Wl,--discard-all -Wl,--discard-locals -Wl,--no-ld-generated-unwind-info -Wl,--orphan-handling=place -no-pie -L/home/artix/my-floppy-distro/x86_64-linux-musl-cross/lib --sysroot=/home/artix/my-floppy-distro/x86_64-linux-musl-cross'
    printf "DROPBEAR: build the source code\n"
    make CC="$CC" PROGRAMS="dbclient" dbclient scp -j$(nproc)
    unset CC
    printf "DROPBEAR: sstrip the binaries\n"
    sstrip ./dbclient
    sstrip ./scp
    ls -al ./dbclient
    ls -al ./scp
    cd ./../
}

# libnl-tiny library needed for wpa_supplicant
libnl_build () {
    rm -rf ./libnl-tiny/
    printf "LIBNL-TINY: git clone a repository\n"
    git clone --depth=1 "https://github.com/openwrt/libnl-tiny.git"
    cd ./libnl-tiny/
    printf "LIBNL-TINY: patch to setup the variables and fix ucred structure for libnl-tiny build\n"
    wgetter "./libnl-tiny.patch" "https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/libnl-tiny.patch"
    patch -p1 < ./libnl-tiny.patch
    rm -rf ./build/
    mkdir ./build/
    cd ./build/
    printf "LIBNL-TINY: configure the source code for toolchain directory installation\n"
    cmake -DCMAKE_INSTALL_PREFIX=/home/artix/my-floppy-distro/x86_64-linux-musl-cross/usr/ ..
    printf "LIBNL-TINY: build the source code\n"
    make -j$(nproc)
    printf "LIBNL-TINY: install the library to a toolchain directory\n"
    make install
    cd ./../
    rm -rf ./build-tc/
    mv ./build/ ./build-tc/
    mkdir ./build/
    cd ./build/
    printf "LIBNL-TINY: configure the source code for host OS directory installation\n"
    cmake -DCMAKE_INSTALL_PREFIX=/usr/ ..
    printf "LIBNL-TINY: build the source code\n"
    make -j$(nproc)
    printf "LIBNL-TINY: install the library to a host OS directory\n"
    sudo make install
    cd ./../
    rm -rf ./build-rt/
    mv ./build/ ./build-rt/
    printf "LIBNL-TINY: patch to fix ucred structure for external usage by wpa_supplicant\n"
    wgetter "./libnl-tiny_ucred.patch" "https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/libnl-tiny_ucred.patch"
    cd ./../
    cd /usr/include/libnl-tiny/
    sudo patch -p1 < /home/artix/my-floppy-distro/libnl-tiny/libnl-tiny_ucred.patch
    cd /home/artix/my-floppy-distro/x86_64-linux-musl-cross/usr/include/libnl-tiny/
    patch -p1 < /home/artix/my-floppy-distro/libnl-tiny/libnl-tiny_ucred.patch
    cd /home/artix/my-floppy-distro/
}

# wpa_supplicant daemon and wpa_cli utility for connecting to WiFi networks
wpa_build () {
    rm -rf ./hostap/
    printf "WPA_SUPPLICANT: git clone a repository\n"
    git clone --depth=1 --branch hostap_2_11 "https://github.com/mikebdp2/hostap.git"
    cd ./hostap/
    printf "WPA_SUPPLICANT: patch to fix linking with a libnl-tiny library\n"
    wgetter "./wpa_libnl.patch" "https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/wpa_libnl.patch"
    patch -p1 < ./wpa_libnl.patch
    printf "WPA_SUPPLICANT: patch to setup the variables\n"
    wgetter "./wpa_makefile.patch" "https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/wpa_makefile.patch"
    patch -p1 < ./wpa_makefile.patch
    cd ./wpa_supplicant/
    printf "WPA_SUPPLICANT: wget a .config file to configure the source code\n"
    wgetter "./wpa_supplicant.cfg" "https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/wpa_supplicant.cfg"
    mover "./wpa_supplicant.cfg" "./.config"
    printf "WPA_SUPPLICANT: build the source code\n"
    export CC="/home/artix/my-floppy-distro/x86_64-linux-musl-cross/bin/x86_64-linux-musl-gcc"
    make clean
    make CC="$CC" wpa_supplicant wpa_cli
    unset CC
    printf "WPA_SUPPLICANT: sstrip the binaries\n"
    sstrip ./wpa_supplicant
    sstrip ./wpa_cli
    ls -al ./wpa_supplicant
    ls -al ./wpa_cli
    cd ./../../
}

# kirc simple IRC client
kirc_build () {
    rm -rf ./kirc/
    printf "KIRC: git clone a repository\n"
    git clone --depth=1 --branch 1.2.2 "https://github.com/mcpcpc/kirc.git"
    cd ./kirc/
    printf "KIRC: patch to setup the variables\n"
    wgetter "./kirc.patch" "https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/kirc.patch"
    patch -p1 < "./kirc.patch"
    export CC="/home/artix/my-floppy-distro/x86_64-linux-musl-cross/bin/x86_64-linux-musl-gcc"
    printf "KIRC: build the source code\n"
    make clean
    make CC="$CC" -j$(nproc)
    unset CC
    printf "KIRC: sstrip a binary\n"
    sstrip ./kirc
    ls -al ./kirc
    printf "KIRC: generate a manual\n"
    man ./kirc.1 > ./kirc.txt
    cd ./../
}

# linux-firmware needed for some Ethernet/WiFi network adapters
firmware_get () {
    printf "LINUX-FIRMWARE: git clone a repository\n"
    git clone --depth=1 "https://github.com/mikebdp2/linux-firmware.git"
}

# Busybox filesystem used by a Linux kernel
busybox_build () {
    printf "BUSYBOX: git clone a repository\n"
    git clone --depth=1 --branch 1_37_stable "https://git.busybox.net/busybox.git"
    cd ./busybox/
    printf "BUSYBOX: upgrade the source code to -Oz optimization level\n"
    rm -rf ./../temp.git/
    mv ./.git/ ./../temp.git/ # Temporarily move ./.git/ to avoid damaging its contents in the process
    printf "BUSYBOX: replace -O2 with -Oz optimization level...\n"
    find . -type f -print0 | xargs -0 sed -i -e "s/-O2/-Os/g"
    mv ./../temp.git/ ./.git/
    git add .
    git commit -m "BUSYBOX: upgrade the source code to -Oz optimization level"
    printf "BUSYBOX: fix for host OS like Arch/Artix Linux with GCC 14 or newer\n"
    sed -i "s/main() {}/int main() {}/" ./scripts/kconfig/lxdialog/check-lxdialog.sh
    printf "BUSYBOX: wget a .config file to configure the source code\n"
    wgetter "./busybox.cfg" "https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/busybox.cfg"
    mover "./busybox.cfg" "./.config"
    printf "BUSYBOX: setup the variables\n"
    sed -i "s|.*CONFIG_CROSS_COMPILER_PREFIX.*|CONFIG_CROSS_COMPILER_PREFIX=\"/home/artix/my-floppy-distro/x86_64-linux-musl-cross/bin/x86_64-linux-musl-\"|" ./.config
    sed -i "s|.*CONFIG_SYSROOT.*|CONFIG_SYSROOT=\"/home/artix/my-floppy-distro/x86_64-linux-musl-cross\"|" ./.config
    sed -i "s|.*CONFIG_EXTRA_CFLAGS.*|CONFIG_EXTRA_CFLAGS=\"-I/home/artix/my-floppy-distro/x86_64-linux-musl-cross/include -static -Os -s -ffunction-sections -fdata-sections -fno-unwind-tables -fno-asynchronous-unwind-tables -fno-stack-protector -fomit-frame-pointer -fmerge-all-constants -fno-ident -fno-math-errno -fno-unroll-loops -ffast-math -fno-plt -fvisibility=hidden -fno-exceptions -march=x86-64 -mtune=generic -fno-align-functions -fno-align-jumps -fno-align-loops -fno-align-labels\"|" ./.config
    sed -i "s|.*CONFIG_EXTRA_LDFLAGS.*|CONFIG_EXTRA_LDFLAGS=\"-L/home/artix/my-floppy-distro/x86_64-linux-musl-cross/lib -static -s -Wl,--gc-sections -Wl,--strip-all -Wl,--build-id=none -Wl,-z,norelro -Wl,--hash-style=sysv -Wl,--no-eh-frame-hdr -Wl,-z,noseparate-code -Wl,--no-undefined-version -Wl,--as-needed -Wl,--sort-common -Wl,--sort-section=alignment -Wl,--compress-debug-sections=none -Wl,--warn-common -Wl,--fatal-warnings -Wl,--discard-all -Wl,--discard-locals -Wl,--no-ld-generated-unwind-info -Wl,--orphan-handling=place -no-pie\"|" ./.config
    printf "BUSYBOX: build the source code\n"
    make ARCH="x86_64" clean
    make ARCH="x86_64" -j$(nproc)
    printf "BUSYBOX: sstrip a binary\n"
    sstrip ./busybox
    ls -al ./busybox
    printf "BUSYBOX: generate the initial filesystem\n"
    rm -rf ./_install/
    make ARCH="x86_64" install
    cp -r ./_install/ ./../filesystem
    cd ./../filesystem/
    printf "BUSYBOX: create the filesytem directories\n"
    mkdir -pv {dev,proc,etc/init.d,sys,tmp,home,var/run,lib/firmware/ath9k_htc,lib/firmware/rtl_nic}
    sudo mknod ./dev/console c 5 1
    sudo mknod ./dev/null c 1 3
    printf "BUSYBOX: wget a welcome message\n"
    wgetter "./welcome" "https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/welcome"
    printf "BUSYBOX: create an inittab file\n"
    rm -f  ./etc/inittab
    cat >> ./etc/inittab << EOF
::sysinit:/etc/init.d/rc
::askfirst:/usr/bin/setsid /bin/cttyhack /bin/sh
::respawn:/usr/bin/setsid /bin/cttyhack /bin/sh
::restart:/sbin/init
::ctrlaltdel:/sbin/reboot
::shutdown:/bin/umount -a -r
EOF
    printf "BUSYBOX: create the init rc script\n"
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
    printf "BUSYBOX: create the udhcpc script\n"
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
    printf "BUSYBOX: create the wpa_supplicant config\n"
    rm -f  ./etc/wpa_supplicant.conf
    cat >> ./etc/wpa_supplicant.conf << EOF
ctrl_interface=/var/run/wpa_supplicant
update_config=1
EOF
    printf "BUSYBOX: create the get_kirc.sh script\n"
    rm -f  ./etc/get_kirc.sh
    cat >> ./etc/get_kirc.sh << EOF
wget "https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/kirc"
wget "https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/kirc.txt"
chmod +x ./kirc
EOF
    chmod +x ./etc/get_kirc.sh
    printf "BUSYBOX: copy the external files\n"
    cp ./../dropbear/dbclient ./usr/bin/dbclient
    cp ./../dropbear/scp ./usr/bin/scp
    cp ./../hostap/wpa_supplicant/wpa_supplicant ./usr/bin/wpa_supplicant
    cp ./../hostap/wpa_supplicant/wpa_cli ./usr/bin/wpa_cli
    ### cp ./../kirc/kirc /usr/bin/kirc
    ### cp ./../kirc/kirc.txt /etc/kirc.txt
    cp ./../linux-firmware/ath9k_htc/htc_9271-1.4.0.fw ./lib/firmware/ath9k_htc/htc_9271-1.4.0.fw
    cp ./../linux-firmware/rtl_nic/rtl816* ./lib/firmware/rtl_nic/
    cd ./usr/bin/
    ln -s ./dbclient ./ssh
    cd ./../../
    printf "BUSYBOX: give the ownership to root\n"
    sudo chown -R root:root ./
    printf "BUSYBOX: compress the directory\n"
    rm -f ./../rootfs.cpio
    rm -f ./../rootfs.cpio.lzma
    find . -print0 | LC_ALL="C" sort -z | cpio -0 -H newc -o --reproducible 2>/dev/null > ./../rootfs.cpio
    strip-nondeterminism -t cpio -T 1770768000 ./../rootfs.cpio
    xz --threads=1 --format=lzma --check=crc32 --lzma1=dict=64MiB,lc=3,lp=0,pb=2,mode=normal,nice=273,mf=bt4,depth=0 < ./../rootfs.cpio > ./../rootfs.cpio.lzma
    rm -f ./../rootfs.cpio
    cd ./../
    ls -al ./rootfs.cpio.lzma
}

syslinux_config() {
    printf "SYSLINUX: generate a standard config file\n"
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
    printf "SYSLINUX: generate a debug config file\n"
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
}

floppinux_build () {
    printf "FLOPPINUX: create a floppy\n"
    rm -f ./floppinux.img
    dd if=/dev/zero of=./floppinux.img bs=1k count=2880
    printf "FLOPPINUX: format a floppy\n"
    mkdosfs -n FLOPPINUX ./floppinux.img
    printf "FLOPPINUX: install a syslinux bootloader\n"
    syslinux --install ./floppinux.img
    printf "FLOPPINUX: mount a floppy\n"
    sudo rm -rf /temp_mnt
    sudo mkdir /temp_mnt
    sudo mount -o loop ./floppinux.img /temp_mnt
    df -B 1
    printf "FLOPPINUX: fill a floppy\n"
    printf "FLOPPINUX: copy a Linux kernel\n"
    ls -al ./bzImage
    sudo cp ./bzImage /temp_mnt
    df -B 1
    printf "FLOPPINUX: copy a rootfs filesystem\n"
    ls -al ./rootfs.cpio.lzma
    sudo cp ./rootfs.cpio.lzma /temp_mnt/rfscpiol.zma
    df -B 1
    printf "FLOPPINUX: copy a syslinux config file\n"
    sudo cp ./syslinux.cfg /temp_mnt
    df -B 1
    printf "FLOPPINUX: unmount a floppy\n"
    sudo umount /temp_mnt
    sudo rm -rf /temp_mnt
    sha256sum ./floppinux.img
}

commands_check
sudo rm -rf /home/artix/my-floppy-distro/
mkdir /home/artix/my-floppy-distro/
cd /home/artix/my-floppy-distro/
sudo ls
musl_get
linux_build
dropbear_build
libnl_build
wpa_build
kirc_build
firmware_get
busybox_build
syslinux_config
floppinux_build
cd ./../

#
