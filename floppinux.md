# FLOPPINUX - An Embedded 🐧Linux on a Single 💾Floppy
## 2026 Edition (v0.3.1-amd64net)

- v0.3.1-amd64net - **February 11, 2026**
- v0.3.1 - **December 21, 2025**
- v0.3.0 - **October 19, 2025**

---

**This is a modified floppinux "amd64net" distribution. It is primarily aimed for embedding as a virtual floppy into the opensource coreboot BIOS of supported AMD PCs ( more information here - http://dangerousprototypes.com/docs/Lenovo_G505S_hacking ), however it may be used for other needs as well. Main features:**

- Architecture changes
  - 2.88 MB floppy image for AMD PCs of x86_64 architecture (seems to work fine in VirtualBox too), with many AMD-specific features enabled
  - Intel CPU support is disabled to save space, however you may re-enable it at cost of something else and use this distro on your Intel
  - Microcode loading is disabled because thanks to opensource coreboot BIOS I do not need this space-taking feature at my Linux kernel
  - Physical floppy drive support (ISA-style DMA support aka ISA_DMA_API) is disabled in Linux kernel too because I needed some extra space
  - Had to disable printk in order to win even more space, to re-enable it for debugging you will have to temporarily disable the other features
- Device support
  - Ethernet
    - Qualcomm/Atheros AR8161/AR8162/QCA8171/QCA8172 - found in coreboot-supported AMD Lenovo G505S - the most powerful no-ME/no-PSP coreboot laptop
    - Realtek RTL8111/RTL8168/RTL8169/RTL8101/RTL8125 - found in coreboot-supported ASUS A88XM-E & AM1I-A desktops and dirt cheap PCIe Ethernet cards
  - WiFi
    - Atheros ath9k family of PCIe WiFi adapters, such as AR9462 that works on 100% opensource without any firmware
    - Atheros ath9k_htc family of USB WiFi adapters, such as AR9271 that seems to need a firmware for unknown reasons
  - USB
    - EHCI (USB 2.0) / OHCI (USB 1.1) support, essential for using the USB WiFi adapters as well as the input devices
    - Please note that it is possible to enable the USB flash drive support / filesystem support at cost of something else
  - ACPI:
    - Had to enable it in order for AR9271 USB WiFi to work on coreboot-supported AMD Lenovo G505S laptop, at cost of disabling printk messages
  - SMP for multiple CPUs / CPU cores support
  - NUMA for a higher performance on systems like ASUS KGPE-D16 - a coreboot-supported AMD-no-PSP server with two Opteron 6386SE 16-core CPUs and 256GB/512GB RAM
  - Pin controllers, especially AMD GPIO pin control
- Software additions
  - wpa_supplicant and wpa_cli
    - This standalone software is essential for connecting to WiFi networks with the supported WiFi adapters
  - Dropbear ssh and scp
    - This standalone software is essential for connecting to other PCs over SSH protocol and therefore providing a "thin client" functionality
  - Kirc IRC client
    - This standalone software is essential for connecting to IRC servers and communicating with other people
    - It did not fit to a floppy, but - since it is only usable if we have network - we will be wgetting it!

Also, I have fixed many bugs like a frozen ping _(had to enable timer-related features)_ and Ctrl+C/Ctrl+Z interrupts _(changes related to TTY and job control)_.

**The instructions below are originally provided by @w84death and have been heavily modded by me (Mike Banon) for this "amd64net" distribution.**

> FLOPPINUX was released in 2021. After four years people find it helpful. Because of that @w84death decided to revisit FLOPPINUX in 2025 and make updated tutorial. This brings bunch of updates like latest kernel and persistent storage.

## Table of Contents

- [Main Project Goals](#main-project-goals)
- [Core Features](#core-features)
- [Linux Kernel](#linux-kernel)
- [64-bit Base OS](#64-bit-base-os)
- [Working Directory](#working-directory)
- [Host OS Requirements](#host-os-requirements)
- [System Requirements](#system-requirements)
- [Emulation](#emulation)
- [Compile Kernel](#compile-kernel)
- [Dropbear](#dropbear)
- [WPA Supplicant](#wpa-supplicant)
- [KIRC](#kirc)
- [Linux Firmware](#linux-firmware)
- [Busybox Toolset](#busybox-toolset)
- [Filesystem](#filesystem)
- [Boot Image](#boot-image)
- [Floppy Disk](#floppy-disk)
- [Summary](#summary)
- [Download](#download)

## Main Project Goals

Think of this as Linux From Scratch but for making single floppy distribution.

> It is meant to be a full workshop (tutorial) that you can follow easily and modify it to your needs. It is a learning exercise. Some base Linux knowledge is needed.

The final distribution is very simple and consists only of minimum of tools and hardware support. As a user you will be able to boot any PC with a floppy drive to a Linux terminal, edit files, and create simple scripts. There is 264KB of space left for your newly created files.

## Core Features

- Fully working distribution booting from a virtual 2.88 MB floppy
- Latest Linux kernel
- Supporting AMD x86_64 CPUs as well as a lot of AMD-related features
- Have a working text editor (Vi) and basic file manipulation commands (move, rename, delete, etc.)
- Have a basic Ethernet/WiFi networking, as well as a basic USB support for USB WiFi & Keyboard/Mouse
- Support for simple scripting

## Linux Kernel

**6.18.9** (released February 2026) is the latest version at the time of writing with full compatibility.

## 64-bit Base OS

This time I will do everything on **Artix** Linux _(Arch without SystemD)_. It is 64-bit operating system based on Arch Linux with a true init freedom. Instructions should work on all POSIX systems. Only difference is getting needed packages.

## Working Directory

**To avoid the possible issues with `~`, I will be using the absolute pathes for `artix` user. If you want these instructions to be copy-paste'able AS-IS, temporarily make a symbolic link:**

```bash
cd /home/
sudo ln -s ./my_username/ ./artix
cd ./artix/
```

Create directory where you will keep all the files.

```bash
mkdir /home/artix/my-floppy-distro/
cd /home/artix/my-floppy-distro/
```

## Host OS Requirements

> You need supporting software to build things. This exact list may vary depending on the system you have.

Install needed software/libs. On Artix:

```bash
sudo pacman -S bc bison cmocka coreutils cpio curl flex gcc m4 make mtools ncurses nss openssl p7zip patch pkgconf syslinux unzip wget xxd zlib git
```

Also, after fully upgrading the system with `pacman -Suy`, I downgrade some packages including GCC to avoid the possible problems I have encountered at other places:
```bash
sudo pacman -U https://archive.artixlinux.org/packages/g/gcc/gcc-14.2.1%2Br753%2Bg1cd744a6828f-1-x86_64.pkg.tar.zst \
https://archive.artixlinux.org/packages/g/gcc-libs/gcc-libs-14.2.1%2Br753%2Bg1cd744a6828f-1-x86_64.pkg.tar.zst \
https://archive.artixlinux.org/packages/p/parted/parted-3.4-2-x86_64.pkg.tar.zst
```

You will also have to enable the Arch Linux "extra" repository in order to get the `sstrip` utility for reducing the ELF file sizes and `strip-nondeterminism` for stable LZMA sizes:

```bash
sudo pacman -S artix-archlinux-support
sudo pacman-key --populate archlinux
sudo nano /etc/pacman.conf
---
==> Add the arch repos in pacman.conf:

#[extra-testing]
#Include = /etc/pacman.d/mirrorlist-arch


[extra]
Include = /etc/pacman.d/mirrorlist-arch


#[multilib-testing]
#Include = /etc/pacman.d/mirrorlist-arch


#[multilib]
#Include = /etc/pacman.d/mirrorlist-arch
---
sudo pacman -Sy
sudo pacman -S elfkickers strip-nondeterminism
```

Cross-compiler:

```bash
wget https://musl.cc/x86_64-linux-musl-cross.tgz
tar -xvf ./x86_64-linux-musl-cross.tgz
```

## System Requirements

- AMD x86_64 CPU _(you could switch to Intel with a Linux kernel config change)_
- 32MB RAM _(approximately, rounded up to a degree of 2, needs to be tested)_
- coreboot+SeaBIOS or alternative way to use a 2.88MB ED Virtual Floppy disk image

## Emulation

> 86Box is also good but slower. Bochs is the best but for debugging, not needed here.

For emulation you may use qemu.

```bash
sudo pacman -S qemu-full
```

Alternatively, VirtualBox may be used.

```bash
sudo pacman -S virtualbox
```

## Kernel

Get the sources for the latest compatible **kernel 6.18.9**:

```bash
git clone --depth=1 --branch v6.18.9 https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
```

After switching to a `./linux/` directory, replace the non-0 optimization flags with -Oz for an aggressive size optimization:

```bash
cd ./linux/
mv ./.git/ ./../temp.git/ # Temporarily move ./.git/ to avoid damaging its contents in the process
find . -type f -print0 | xargs -0 sed -i -e "s/-O1/-Oz/g"
find . -type f -print0 | xargs -0 sed -i -e "s/-O2/-Oz/g"
find . -type f -print0 | xargs -0 sed -i -e "s/-O3/-Oz/g"
find . -type f -print0 | xargs -0 sed -i -e "s/-Os/-Oz/g"
mv ./../temp.git/ ./.git/
```

In order for your further changes to be easily noticeable, lets make a local commit of these "-Oz" changes. Check your `.gitconfig` contents:
```bash
cat /home/artix/.gitconfig
```

If it is empty, do the following setup:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

Now, lets commit the changes:

```bash
git add .
git commit -m "Upgrade the sources to -Oz optimization"
```

Disable the microcode loading and networking selftests:

```bash
cat >> ./linux.patch << EOF
diff --git a/arch/x86/Kconfig b/arch/x86/Kconfig
index a3700766a..7da1171b0 100644
--- a/arch/x86/Kconfig
+++ b/arch/x86/Kconfig
@@ -1318,7 +1318,7 @@ config X86_REBOOTFIXUPS
 	  Say N otherwise.
 
 config MICROCODE
-	def_bool y
+	def_bool n
 	depends on CPU_SUP_AMD || CPU_SUP_INTEL
 	select CRYPTO_LIB_SHA256 if CPU_SUP_AMD
 
diff --git a/net/Kconfig b/net/Kconfig
index 1d3f757d4..1560517af 100644
--- a/net/Kconfig
+++ b/net/Kconfig
@@ -476,8 +476,8 @@ config NET_IEEE8021Q_HELPERS
 	bool
 
 config NET_SELFTESTS
-	def_tristate PHYLIB
-	depends on PHYLIB && INET
+	bool
+	default n
 
 config NET_SOCK_MSG
 	bool
EOF
patch -p1 < ./linux.patch
```

Now, lets configure and build our custom kernel. First create tiniest base configuration:

```bash
make ARCH="x86_64" tinyconfig
```

> This is a bootstrap with absolute minimum features. Just enough to boot the system. We want a little bit more.

Add additonal config settings on top of it:

```bash
make ARCH="x86_64" menuconfig
```
Important: Do not uncheck anything in options unless specified so. Some of those options are important. You can uncheck but on your own risk.

**NOTE: you may either pick the options below manually, or just wget a final config:**

```bash
rm -f ./.config
wget https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/linux.cfg
mv ./linux.cfg ./.config
```

From menus choose those options:

- Power management and ACPI options
  - Device power management core functionality: CONFIG_PM
  - ACPI (Advanced Configuration and Power Interface) Support: CONFIG_ACPI
    - Disable "Allow upgrading ACPI tables via initrd": CONFIG_ACPI_TABLE_UPGRADE
    - Disable "Debug Statements": CONFIG_ACPI_DEBUG
  - CPU Frequency scaling
    - Disable "Intel P state control": CONFIG_X86_INTEL_PSTATE
- Processor type and features
  - Symmetric multi-processing support: CONFIG_SMP
  - AMD ACPI2Platform devices support: CONFIG_X86_AMD_PLATFORM_DEVICE
  - Supported processor vendors: CONFIG_PROCESSOR_SELECT
    - Disable everything except "Support AMD processors": CONFIG_CPU_SUP_AMD
  - Performance monitoring
    - Disable "Intel/AMD rapl performance events": CONFIG_PERF_EVENTS_INTEL_RAPL
  - NUMA Memory Allocation and Scheduler Support: CONFIG_NUMA
- General Setup
  - Kernel compression mode: CONFIG_KERNEL_XZ (XZ is the best here)
  - Memory placement aware NUMA scheduler: CONFIG_NUMA_BALANCING
  - Initial RAM filesystem and RAM disk (initramfs/initrd)
    - Original instruction: Support initial ramdisk/ramfs compressed using XZ (CONFIG_RD_XZ) and **uncheck everything else**
    - My instruction: Support initial ramdisk/ramfs compressed using LZMA (CONFIG_RD_LZMA) and **uncheck everything else** (LZMA overall is smaller here)
  - Configure standard kernel features (expert users)
    - Original instruction: Enable support for printk: CONFIG_PRINTK
    - My instruction: Do not enable support for printk (CONFIG_PRINTK) because it is way too fat
    - Posix Clocks & timers: CONFIG_POSIX_TIMERS
    - Enable futex support: CONFIG_FUTEX
    - Enable eventpoll support: CONFIG_EPOLL
- Bus options
  - Original instruction: ISA-style DMA support: ISA_DMA_API (for ARCH_MAY_HAVE_PC_FDC for CONFIG_BLK_DEV_FD)
  - My instruction: do not enable this option to save a lot of space if we do not use a physical floppy drive
- Enable the block layer: CONFIG_BLOCK
- Executable file formats
  - Kernel support for ELF binaries: CONFIG_BINFMT_ELF
  - Kernel support for scripts starting with #!: CONFIG_BINFMT_SCRIPT
- Memory Management options
  - Disable "Support for paging of anonymous memory (swap)": CONFIG_SWAP
- Networking support: CONFIG_NET
  - Networking options
    - Packet socket: CONFIG_PACKET
    - Unix domain sockets: CONFIG_UNIX
    - TCP/IP networking: CONFIG_INET
      - Disable "INET: socket monitoring interface": CONFIG_INET_DIAG
      - Disable "The IPv6 protocol": CONFIG_IPV6
    - Disable "Receive packet steering": CONFIG_RPS
  - Wireless: CONFIG_WIRELESS
    - cfg80211 - wireless configuration API: CONFIG_CFG80211
      - Disable "Support CRDA": CONFIG_CFG80211_CRDA_SUPPORT
      - Generic IEEE 802.11 Networking Stack (mac80211): CONFIG_MAC80211
      - cfg80211 certification onus: CONFIG_CFG80211_CERTIFICATION_ONUS
        - Disable "require regdb signature": CONFIG_CFG80211_REQUIRE_SIGNED_REGDB
    - Disable "Netlink interface for ethtool": CONFIG_ETHTOOL_NETLINK
- Device Drivers
  - PCI Support: CONFIG_PCI
    - Disable "VGA Arbitration": CONFIG_VGA_ARB
  - Generic Driver Options
    - Maintain a devtmpfs filesystem to mount at /dev: CONFIG_DEVTMPFS
      - Automount devtmpfs at /dev, after the kernel mounted the rootfs: CONFIG_DEVTMPFS_MOUNT
  - Block devices
    - Normal floppydisk support: CONFIG_BLK_DEV_FD (depends on ISA_DMA_API for ARCH_MAY_HAVE_PC_FDC)
    - RAM block device support: CONFIG_BLK_DEV_RAM
      - Default number of RAM disk: 1 (CONFIG_BLK_DEV_RAM_COUNT)
  - Misc devices
    - Disable "Intel Management Engine Interface": CONFIG_INTEL_MEI
  - USB support: CONFIG_USB_SUPPORT
    - Support for Host-side USB: CONFIG_USB
      - EHCI HCD (USB 2.0) support: CONFIG_USB_EHCI_HCD
      - OHCI HCD (USB 1.1) support: CONFIG_USB_OHCI_HCD
  - Network device support: CONFIG_NETDEVICES
    - Disable "Network core driver support": CONFIG_NET_CORE
    - Ethernet driver support: CONFIG_ETHERNET
      - **Uncheck everything there before proceeding**
      - AMD devices: CONFIG_NET_VENDOR_AMD
        - AMD PCnet32 PCI support: CONFIG_PCNET32 (for VirtualBox)
      - Atheros devices: CONFIG_NET_VENDOR_ATHEROS
        - Qualcomm Atheros AR816x/AR817x support: CONFIG_ALX
      - Realtek devices: CONFIG_NET_VENDOR_REALTEK
        - Realtek 8169/8168/8101/8125 ethernet support: CONFIG_R8169 (also supports 8111)
    - Wireless LAN: CONFIG_WLAN
      - **Uncheck everything there before proceeding**
      - Atheros/Qualcomm devices: CONFIG_WLAN_VENDOR_ATH
        - Atheros 802.11n wireless cards support: CONFIG_ATH9K
        - Disable "Atheros bluetooth coexistence support": CONFIG_ATH9K_BTCOEX_SUPPORT (we did not enable the Bluetooth of AR9462 card)
        - Atheros ath9k ACK timeout estimation algorithm: CONFIG_ATH9K_DYNACK
      - Atheros HTC based wireless cards support: CONFIG_ATH9K_HTC
  - Input device support
    - Generic input layer (needed for keyboard, mouse, ...): CONFIG_INPUT
      - Mice: CONFIG_INPUT_MOUSE
        - Elantech PS/2 protocol extension: CONFIG_MOUSE_PS2_ELANTECH (may be a part of AMD Lenovo G505S laptop)
      - Hardware I/O ports
        - Disable "Serial port line discipline": CONFIG_SERIO_SERPORT
  - Character devices
    - Enable TTY: CONFIG_TTY
    - Disable "Unix98 PTY support": CONFIG_UNIX98_PTYS
    - Disable "Legacy (BSD) PTY support": CONFIG_LEGACY_PTYS
  - Disable "PPS support": CONFIG_PPS
  - PTP clock support
    - Disable "PTP clock support": CONFIG_PTP_1588_CLOCK
  - Pin controllers: CONFIG_PINCTRL
    - AMD GPIO pin control: CONFIG_PINCTRL_AMD
  - GPIO support
    - Disable "Character device (/dev/gpiochipN) support": CONFIG_GPIO_CDEV
  - Thermal drivers
    - Disable "Thermal netlink management": CONFIG_THERMAL_NETLINK
  - Real Time Clock: CONFIG_RTC_CLASS
  - NVMEM Support:
    - Disable "/sys/bus/nvmem/devices/*/nvmem (sysfs interface)": CONFIG_NVMEM_SYSFS
- File systems
  - DOS/FAT/EXFAT/NT Filesystems
    - MSDOS fs support: CONFIG_MSDOS_FS
  - Pseudo filesystems
    - /proc file system support: CONFIG_PROC_FS
    - sysfs file system support: CONFIG_SYSFS
    - Disable "Enable /proc page monitoring": CONFIG_PROC_PAGE_MONITOR
  - Disable "Network File Systems": CONFIG_NETWORK_FILESYSTEMS
  - Native language support
    - Codepage 437: CONFIG_NLS_CODEPAGE_437
- Security options
  - Disable "Enable access key retention support": CONFIG_KEYS
- Cryptographic API
  - Public-key cryptography
    - Disable "RSA (Rivest-Shamir-Adleman): CONFIG_CRYPTO_RSA
  - Hashes, digests, and MACs
    - Disable "SHA-224 and SHA-256": CONFIG_CRYPTO_SHA256  
  - Disable "Hardware crypto devices": CONFIG_CRYPTO_HW
  - Disable "Asymmetric (public-key cryptographic) key type": CONFIG_ASYMMETRIC_KEY_TYPE
- Library routines
  - Original instruction: XZ decompression: CONFIG_DECOMPRESS_XZ (selected by RD_XZ && BLK_DEV_INITRD) and **uncheck everything under it**
  - My instruction: LZMA decompression: CONFIG_DECOMPRESS_LZMA (selected by RD_LZMA && BLK_DEV_INITRD) (LZMA overall is smaller here)

Exit configuration (yes, save settings to .config).

Time for compiling!

### Compile Kernel

```bash
make ARCH="x86_64" clean && make ARCH="x86_64" bzImage -j$(nproc) && ls -al ./arch/x86_64/boot/bzImage
```

This will take a while depending on the speed of your CPU. In the end the kernel will be created in **arch/x86/boot/** as **bzImage** file.

Copy kernel to our **main directory** and **go back to it**:
 
```bash
cp ./arch/x86_64/boot/bzImage ./../
cd ./../
```

## Dropbear

```bash
git clone --depth=1 --branch DROPBEAR_2025.89 https://github.com/mkj/dropbear.git
cd ./dropbear/
make clean
make distclean
export CC="/home/artix/my-floppy-distro/x86_64-linux-musl-cross/bin/x86_64-linux-musl-gcc"
./configure --host=x86_64-linux-musl --prefix=/usr --enable-static --disable-zlib --disable-syslog --disable-lastlog --disable-utmp --disable-utmpx --disable-wtmp --disable-wtmpx --disable-shadow --enable-bundled-libtom --disable-openpty --disable-loginfunc --disable-pututline --disable-pututxline --without-pam --disable-plugin CC='/home/artix/my-floppy-distro/x86_64-linux-musl-cross/bin/x86_64-linux-musl-gcc' \
CFLAGS='-DDROPBEAR_ECDSA=0 -DDROPBEAR_ECDH=0 -static -Os -s -ffunction-sections -fdata-sections -fno-unwind-tables -fno-asynchronous-unwind-tables -fno-stack-protector -fomit-frame-pointer -fmerge-all-constants -fno-ident -fno-math-errno -fno-unroll-loops -ffast-math -fno-plt -fno-exceptions -march=x86-64 -mtune=generic -fno-align-functions -fno-align-jumps -fno-align-loops -fno-align-labels -I/home/artix/my-floppy-distro/x86_64-linux-musl-cross/include --sysroot=/home/artix/my-floppy-distro/x86_64-linux-musl-cross' \
LDFLAGS='-L/home/artix/my-floppy-distro/x86_64-linux-musl-cross/lib -L/home/artix/my-floppy-distro/x86_64-linux-musl-cross/x86_64-linux-musl/lib -static -s -Wl,--gc-sections -Wl,--strip-all -Wl,--build-id=none -Wl,-z,norelro -Wl,--hash-style=sysv -Wl,--no-eh-frame-hdr -Wl,-z,noseparate-code -Wl,--no-undefined-version -Wl,--as-needed -Wl,--sort-common -Wl,--sort-section=alignment -Wl,--compress-debug-sections=none -Wl,--warn-common -Wl,--discard-all -Wl,--discard-locals -Wl,--no-ld-generated-unwind-info -Wl,--orphan-handling=place -no-pie -L/home/artix/my-floppy-distro/x86_64-linux-musl-cross/lib --sysroot=/home/artix/my-floppy-distro/x86_64-linux-musl-cross'
make CC="$CC" PROGRAMS="dbclient" dbclient scp
unset CC
sstrip ./dbclient
sstrip ./scp
ls -al ./dbclient
ls -al ./scp
cd ./../
```

## WPA Supplicant

libnl-tiny

```bash
git clone --depth=1 https://github.com/openwrt/libnl-tiny.git
cd ./libnl-tiny/
wget https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/libnl-tiny.patch
patch -p1 < ./libnl-tiny.patch
rm -rf ./build/
mkdir ./build/
cd ./build/
cmake -DCMAKE_INSTALL_PREFIX=/home/artix/my-floppy-distro/x86_64-linux-musl-cross/usr/ ..
make
make install
cd ./../
rm -rf ./build-tc/
mv ./build/ ./build-tc/
mkdir ./build/
cd ./build/
cmake -DCMAKE_INSTALL_PREFIX=/usr/ ..
make
sudo make install
cd ./../
rm -rf ./build-rt/
mv ./build/ ./build-rt/
wget https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/libnl-tiny_ucred.patch
cd ./../
cd /usr/include/libnl-tiny/
sudo patch -p1 < /home/artix/my-floppy-distro/libnl-tiny/libnl-tiny_ucred.patch
cd /home/artix/my-floppy-distro/x86_64-linux-musl-cross/usr/include/libnl-tiny/
patch -p1 < /home/artix/my-floppy-distro/libnl-tiny/libnl-tiny_ucred.patch
cd /home/artix/my-floppy-distro/
```

wpa_supplicant

```bash
git clone --depth=1 --branch hostap_2_11 https://git.w1.fi/hostap.git
cd ./hostap/
wget --output-document=./wpa_libs.patch https://git.w1.fi/cgit/hostap/patch/?id=c13c7b6a1db3361dccc146719f0c676bc975af2e
patch -p1 < ./wpa_libs.patch
wget https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/wpa_makefile.patch
patch -p1 < ./wpa_makefile.patch
wget https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/wpa_supplicant.cfg
mv ./wpa_supplicant.cfg ./wpa_supplicant/.config
cd ./wpa_supplicant/
export CC="/home/artix/my-floppy-distro/x86_64-linux-musl-cross/bin/x86_64-linux-musl-gcc"
make clean && make CC="$CC" wpa_supplicant wpa_cli
unset CC
sstrip ./wpa_supplicant
sstrip ./wpa_cli
ls -al ./wpa_supplicant
ls -al ./wpa_cli
cd ./../../
```

## KIRC

```bash
git clone --depth=1 --branch 1.2.2 https://github.com/mcpcpc/kirc.git
cd ./kirc/
wget https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/kirc.patch
patch -p1 < ./kirc.patch
export CC="/home/artix/my-floppy-distro/x86_64-linux-musl-cross/bin/x86_64-linux-musl-gcc"
make clean && make CC="$CC"
unset CC
sstrip ./kirc
ls -al ./kirc
man ./kirc.1 > ./kirc.txt
cd ./../
```

## Linux Firmware

```bash
git clone --depth=1 https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git
```

## Busybox Toolset

Without tools kernel will just boot and you will not be able to do anything. One of the most popular lightweight tools is BusyBox. It replaces the standard GNU utilities with way smaller but still functional alternatives, perfect for embedded needs.

Get the **1.37.0** version from busybox.net or Github mirror. Download the file, extract it, and change directory:

> Remember to be in the working directory.

```bash
git clone --depth=1 --branch 1_37_stable https://git.busybox.net/busybox.git
```

After switching to a `./busybox/` directory, replace the O2 optimization flags with -Os for a size optimization: _(musl.cc toolchain's GCC is too old for -Oz)_

```bash
cd ./busybox/
mv ./.git/ ./../temp.git/ # Temporarily move ./.git/ to avoid damaging its contents in the process
find . -type f -print0 | xargs -0 sed -i -e "s/-O2/-Os/g"
mv ./../temp.git/ ./.git/
```

As with kernel you need to create starting configuration:

```bash
make ARCH="x86_64" allnoconfig
```

> You may skip this following fix if you are building on Debian/Fedora

Fix for **GCC 14+ Linux based distributions** like Arch:

```bash
sed -i "s/main() {}/int main() {}/" ./scripts/kconfig/lxdialog/check-lxdialog.sh
```

> Now the fun part. You need to **choose what tools you want**. Each menu entry will show how much more KB will be taken if you choose it. So choose it wisely :) For the first time use my selection.

Run the configurator:

```bash
make ARCH="x86_64" menuconfig
```

**NOTE: you may either pick the options below manually, or just wget a final config:**

```bash
rm -f ./.config
wget https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/busybox.cfg
mv ./busybox.cfg ./.config
```

Choose the following options. Remember to **do not uncheck** anything if not stated here.

- Settings
  - Support --long-options: CONFIG_LONG_OPTS
  - Support files > 2 GB: CONFIG_LFS
  - Clean up all memory before exiting (usually not needed): CONFIG_FEATURE_CLEAN_UP
  - Build static binary (no shared libs): CONFIG_STATIC
  - Use sendfile system call: CONFIG_FEATURE_USE_SENDFILE
  - Use clock_gettime(CLOCK_MONOTONIC) syscall: CONFIG_MONOTONIC_SYSCALL
  - Support Unicode: CONFIG_UNICODE_SUPPORT
    - Allow wide Unicode characters on output: CONFIG_UNICODE_WIDE_WCHARS
- Coreutils
  - cat: CONFIG_CAT
  - chmod: CONFIG_CHMOD
  - cp: CONFIG_CP
  - date: CONFIG_DATE
  - df: CONFIG_DF
  - echo: CONFIG_ECHO
  - ln: CONFIG_LN
  - ls: CONFIG_LS
  - mkdir: CONFIG_MKDIR
  - mv: CONFIG_MV
  - pwd: CONFIG_PWD
  - rm: CONFIG_RM
  - sleep: CONFIG_SLEEP
  - sync: CONFIG_SYNC
  - test: CONFIG_TEST
    - test as [: CONFIG_TEST1
    - test as [[: CONFIG_TEST2
  - timeout: CONFIG_TIMEOUT
- Console Utilities
  - clear: CONFIG_CLEAR
- Editors
  - vi: CONFIG_VI
- Init Utilities
  - init: CONFIG_INIT
    - **uncheck** everything else (inside init: keep [*] only on init in this page)
- Linux System Utilities
  - lsusb: CONFIG_LSUSB
  - lspci: CONFIG_LSPCI
  - mdev: CONFIG_MDEV
  - mount: CONFIG_MOUNT
    - Support lots of -o flags: CONFIG_FEATURE_MOUNT_FLAGS
    - **uncheck** everything else
  - setsid: CONFIG_SETSID
  - umount: CONFIG_UMOUNT
- Miscellaneous Utilities
  - beep: CONFIG_BEEP
  - **uncheck** readahead: CONFIG_READAHEAD
- Networking Utilities
  - ifconfig: CONFIG_IFCONFIG
  - ifplugd: CONFIG_IFPLUGD
  - ping: CONFIG_PING
  - route: CONFIG_ROUTE
  - wget: CONFIG_WGET
  - udhcpc: CONFIG_UDHCPC
    - Absolute path to config script (CONFIG_UDHCPC_DEFAULT_SCRIPT): /etc/udhcpc.sh
    - Maximum verbosity level (0..9) (CONFIG_UDHCP_DEBUG): 0
- Process Utilities
  - Faster /proc scanning code (+100 bytes): CONFIG_FEATURE_FAST_TOP
  - free: CONFIG_FREE
  - kill: CONFIG_KILL
  - ps: CONFIG_PS
  - uptime: CONFIG_UPTIME
- Shells
  - Choose alias as (ash): CONFIG_SH_IS_ASH
  - ash: CONFIG_ASH
    - Optimize for size instead of speed: CONFIG_ASH_OPTIMIZE_FOR_SIZE
    - Job control: CONFIG_ASH_JOB_CONTROL
    - Alias support: CONFIG_ASH_ALIAS
  - cttyhack: CONFIG_CTTYHACK
  <!--- Help support-->

Now exit with save config.

### Cross Compiler Setup

> Our target system needs to be 64-bit MUSL. To compile it on 64-bit no-MUSL system we need a cross compiler. You can setup this by hand in the menuconfig or just copy and paste those four lines.

Setup paths:

```bash
sed -i "s|.*CONFIG_CROSS_COMPILER_PREFIX.*|CONFIG_CROSS_COMPILER_PREFIX=\"/home/artix/my-floppy-distro/x86_64-linux-musl-cross/bin/x86_64-linux-musl-\"|" ./.config

sed -i "s|.*CONFIG_SYSROOT.*|CONFIG_SYSROOT=\"/home/artix/my-floppy-distro/x86_64-linux-musl-cross\"|" ./.config

sed -i "s|.*CONFIG_EXTRA_CFLAGS.*|CONFIG_EXTRA_CFLAGS=\"-I/home/artix/my-floppy-distro/x86_64-linux-musl-cross/include -static -Os -s -ffunction-sections -fdata-sections -fno-unwind-tables -fno-asynchronous-unwind-tables -fno-stack-protector -fomit-frame-pointer -fmerge-all-constants -fno-ident -fno-math-errno -fno-unroll-loops -ffast-math -fno-plt -fvisibility=hidden -fno-exceptions -march=x86-64 -mtune=generic -fno-align-functions -fno-align-jumps -fno-align-loops -fno-align-labels\"|" ./.config

sed -i "s|.*CONFIG_EXTRA_LDFLAGS.*|CONFIG_EXTRA_LDFLAGS=\"-L/home/artix/my-floppy-distro/x86_64-linux-musl-cross/lib -static -s -Wl,--gc-sections -Wl,--strip-all -Wl,--build-id=none -Wl,-z,norelro -Wl,--hash-style=sysv -Wl,--no-eh-frame-hdr -Wl,-z,noseparate-code -Wl,--no-undefined-version -Wl,--as-needed -Wl,--sort-common -Wl,--sort-section=alignment -Wl,--compress-debug-sections=none -Wl,--warn-common -Wl,--fatal-warnings -Wl,--discard-all -Wl,--discard-locals -Wl,--no-ld-generated-unwind-info -Wl,--orphan-handling=place -no-pie\"|" ./.config
```

### Compile BusyBox

Build tools and create base filesystem ("install"). It will ask for options, just **press enter** for default for all of them.

```bash
make ARCH="x86_64" clean && make ARCH="x86_64" -j$(nproc) && sstrip ./busybox && make ARCH="x86_64" install
```

This will create a filesystem with all the files at `./_install/`. Move it to our main directory with renaming and go to it.

```bash
mv ./_install/ ./../filesystem
cd ./../filesystem/
```

## Filesystem

You got kernel and basic tools but the system still needs some additional directory structure.

> This created minimum viable directory structure for satisfying the basic requirements of a Linux system.

> Remember to be in the ./filesystem/ directory.

```bash
mkdir -pv {dev,proc,etc/init.d,sys,tmp,home,var/run,lib/firmware/ath9k_htc,lib/firmware/rtl_nic}
sudo mknod ./dev/console c 5 1
sudo mknod ./dev/null c 1 3
```

Next step is to add minimum configuration files. First one is a welcome message that will be shown after booting.

> Here is the first real opportunity to go wild and make this your own signature.

```bash
cat >> ./welcome << EOF
Your welome message or ASCII art.
EOF
```

Or download my `welcome` file.

```bash
wget https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/welcome
```

It looks like that:

```
$ cat ./welcome

                __________________
               /_/  FLOPPINUX  /_/;
              / '  boot disk  ' //
             / '-------------' //
            /   .---------.   //
           /   / AMD64NET /  //
          .___/__________/__//   2880KiB
          '===\__________\=='   3.5"

______ FLOPPINUX_V_0.3.1-AMD64NET _________________________
______ AN_EMBEDDED_SINGLE_FLOPPY_LINUX_DISTRIBUTION _______
______ BY_KRZYSZTOF_KRYSTIAN_JANKOWSKI_AND_MIKE_BANON _____
______ 2026.02 ____________________________________________
```

> Back to serious stuff. Inittab tells the system what to do in critical states like starting, exiting and restarting. It points to the initialization script rc that is the first thing that our OS will run before dropping into the shell.

Create an inittab file:

```bash
cat >> ./etc/inittab << EOF
::sysinit:/etc/init.d/rc
::askfirst:/usr/bin/setsid /bin/cttyhack /bin/sh
::respawn:/usr/bin/setsid /bin/cttyhack /bin/sh
::restart:/sbin/init
::ctrlaltdel:/sbin/reboot
::shutdown:/bin/umount -a -r
EOF
```

And the init rc script:

```bash
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
```

And the udhcpc script:

```bash
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
```

And the wpa_supplicant config:

```bash
cat >> ./etc/wpa_supplicant.conf << EOF
ctrl_interface=/var/run/wpa_supplicant
update_config=1
EOF
```

And the get_kirc.sh script:

```bash
cat >> ./etc/get_kirc.sh << EOF
wget https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/kirc
wget https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/kirc.txt
chmod +x ./kirc
EOF
```

Copy the files that will be created as a part of subsequent instructions:

```bash
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
```

Make the scripts executable, copy the additional files and give the ownership of all files to root:

```bash
chmod +x ./etc/init.d/rc
chmod +x ./etc/udhcpc.sh
chmod +x ./etc/get_kirc.sh
cp ./../dropbear/dbclient ./usr/bin/dbclient
cp ./../dropbear/scp ./usr/bin/scp
cp ./../hostap/wpa_supplicant/wpa_supplicant ./usr/bin/wpa_supplicant
cp ./../hostap/wpa_supplicant/wpa_cli ./usr/bin/wpa_cli
### cp ./../kirc/kirc ./usr/bin/kirc
### cp ./../kirc/kirc.txt ./home/kirc.txt
cp ./../linux-firmware/ath9k_htc/htc_9271-1.4.0.fw ./lib/firmware/ath9k_htc/htc_9271-1.4.0.fw
cp ./../linux-firmware/rtl_nic/rtl816* ./lib/firmware/rtl_nic/
cd ./usr/bin/
ln -s dbclient ssh
cd ./../../
sudo chown -R root:root ./
```

Compress this directory into one file. Then go back to working directory.

```bash
rm -f ./../rootfs.cpio
rm -f ./../rootfs.cpio.lzma
find . -print0 | LC_ALL="C" sort -z | cpio -0 -H newc -o --reproducible 2>/dev/null > ./../rootfs.cpio
strip-nondeterminism -t cpio -T 1770768000 ./../rootfs.cpio
xz --threads=1 --format=lzma --check=crc32 --lzma1=dict=64MiB,lc=3,lp=0,pb=2,mode=normal,nice=273,mf=bt4,depth=0 < ./../rootfs.cpio > ./../rootfs.cpio.lzma
rm -f ./../rootfs.cpio
cd ./../
ls -al ./rootfs.cpio.lzma
```

Create booting configuration.

> Another place to tweak parameters for your variant. Text after SAY is what will be displayed on the screen as first, usualy a name of the OS.

> The tsc=unstable is useful on some (real) computers to get rid of randomly shown warnings about Time Stamp Counter.

> Remember to be in the working directory.

```bash
cat >> ./syslinux.cfg << EOF
DEFAULT floppinux
LABEL floppinux
SAY [ BOOTING FLOPPINUX VERSION 0.3.1-AMD64NET ]
KERNEL bzImage
INITRD rfscpiol.zma
APPEND root=/dev/ram rdinit=/etc/init.d/rc console=tty0 tsc=unstable
EOF
```

Make it executable:

```bash
chmod +x ./syslinux.cfg
```

Filesystem is ready. Final step is to **put this all on a floppy**!

## Boot Image

First we need an empty file in exact size of a floppy disk. Then format and make it bootable.

Create empty floppy image:

```bash
rm -f ./floppinux.img
dd if=/dev/zero of=./floppinux.img bs=1k count=2880
```

Format it and create bootloader:

```bash
mkdosfs -n FLOPPINUX ./floppinux.img
syslinux --install ./floppinux.img
```

Mount it and copy syslinux, kernel, and filesystem onto it:

```bash
sudo mount -o loop ./floppinux.img /mnt
rm -f ./bzImage
cp ./linux/arch/x86_64/boot/bzImage ./bzImage
sudo cp ./bzImage /mnt
sudo cp ./rootfs.cpio.lzma /mnt/rfscpiol.zma
sudo cp ./syslinux.cfg /mnt
df -B 1
sudo umount /mnt
```

Done!

### Test in emulator

It's good to test before wasting time for the real floppy to burn.

Boot the new OS in qemu:

```bash
qemu-system-x86_64 -fda ./floppinux.img -m 32M
```

If it worked that means You have successfully created your own distribution! Congratulations!

The **floppinux.img** image is ready to burn onto a floppy and boot on real hardware!

## Floppy Disk

### <!> Important <!>

Change XXX to floppy drive name in your system. In my case it is **sdb**. Choosing wrongly will NUKE YOUR PARTITION and REMOVE all of your files! Think twice. Or use some GUI application for that.

```bash
sudo dd if=./floppinux.img of=/dev/XXX bs=512 conv=notrunc,sync,fsync iflag=nocache oflag=direct status=progress
```

After 10 minutes I got a freshly burned floppy.

## Debugging

If you need more verbose logging use those syslinux.cfg settings.

```
cat >> syslinux.cfg << EOF
DEFAULT floppinux
LABEL floppinux
SAY [ BOOTING FLOPPINUX VERSION 0.3.1-AMD64NET DEBUG ]
KERNEL bzImage
INITRD rfscpiol.zma
APPEND root=/dev/ram rdinit=/etc/init.d/rc console=tty0 ignore_loglevel earlyprintk=tty0 loglevel=8 tsc=unstable
EOF
```

## Summary

- FLOPPINUX: **0.3.1** (February 2026)
- Linux Kernel: **6.18.9**
- Busybox: **1.37.0**
- Image size: 2880KiB / 2.88MiB
- Kernel size: 2249728 Bytes (bzImage)
- Tools: 501939 Bytes (rfscpiol.zma)
- Free space left (df -B 1): **Less than 1 KiB**

### System Tools

**TO BE EXPANDED**

#### File & Directory Manipulation
- ```cat``` - display file contents
- ```cp``` - copy files and directories
- ```mv``` - move/rename files and directories
- ```rm``` - remove files and directories
- ```ls``` - list directory contents
- ```mkdir``` - creates directory

#### System Information & Management
- ```df -h``` - display filesystem disk space usage
- ```sync``` - force write of buffered data to disk - use this after any changes to the floppy filesystem
- ```mount``` - mount filesystems
- ```umount``` - unmount filesystems

#### Text Processing & Output
- ```echo``` - display text output
- ```more``` - page through text output

#### Utilities
- ```clear``` - clear terminal screen
- ```test``` - evaluate conditional expressions

### Applications

- ```vi``` - text editor

## Download

- [ERROR - FLOPPINUX 0.3.1-AMD64NET Floppy Image 2.88MB](http://error.img)

---

```
                         __________________
                        /_/  FLOPPINUX  /_/;
                       / '  boot disk  ' //
                      / '-------------' //
                     /   .---------.   //
                    /   / AMD64NET /  //
                   .___/__________/__//   2880KiB
                   '===\__________\=='   3.5"


                Now go and make something fun with it!
```

**FLOPPINUX - An Embedded Single Floppy Linux Distribution**
**By Krzysztof Krystian Jankowski and Mike Banon**
**2026.02**
