# FLOPPINUX-AMD64NET - An embedded 🐧Linux on a single 💾Floppy with 🔗Ethernet and 📶WiFi

**My heavily-modified floppinux distribution is primarily aimed at embedding as a virtual floppy into the opensource coreboot BIOS of supported AMD PCs _( more information here - [http://dangerousprototypes.com/docs/Lenovo_G505S_hacking](http://dangerousprototypes.com/docs/Lenovo_G505S_hacking) )_. However, it may be used for other needs as well, or as a base for something even bigger...**

## Table of Contents

- [Build from Scratch](#build-from-scratch)
- [Download my Builds](#download-my-builds)
- [System Requirements](#system-requirements)
- [Emulation](#emulation)
- [Footprint](#footprint)
- [Features](#features)
- [Kernel Configuration](#kernel-configuration)
- [Busybox Toolset](#busybox-toolset)
- [Included Software](#included-software)
- [Support the Project](#support-the-project)

## Build from Scratch

Just run [floppinux-amd64net.sh](https://github.com/mikebdp2/floppinux-amd64net/blob/main/floppinux-amd64net.sh) script of this repository! It will create a `./my-floppy-distro/` subdirectory; there, it will download and build all the required components and will produce three floppy images as result _(they are nearly the same, the only difference is a supported Ethernet controller model)_. To understand how this stuff works, carefully look through this script and also step-by-step workshop of the [original project](https://github.com/w84death/floppinux).

## Download my Builds

- [flpnxath.img](https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/floppies/flpnxath.img) - Qualcomm/Atheros AR8161/AR8162/QCA8171/QCA8172, **for AMD Lenovo G505S**
- [flpnxrtl.img](https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/floppies/flpnxrtl.img) - Realtek RTL8111/RTL8168/RTL8169/RTL8101/RTL8125, **for ASUS A88XM-E / AM1I-A** _(and also KGPE-D16 with a standalone Realtek PCIe Ethernet card)_
- [flpnxpcn.img](https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/floppies/flpnxpcn.img) - AMD PCnet-FAST III Am79C973/79C971, **for Oracle VirtualBox**

## System Requirements

- AMD x86_64 CPU _(you could switch to Intel with a Linux kernel config change)_
- 512MB RAM _(it seems no physical DDR3 modules exist that are smaller than this)_
- coreboot+SeaBIOS or an alternative way to use a 2.88MB ED Virtual Floppy disk image

## Emulation

- Create a new VirtualBox machine - either Other Linux (64-bit) or Other/Unknown (64-bit)
- Go to its storage settings, add a Floppy Disk controller, add a [flpnxpcn.img](https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/floppies/flpnxpcn.img) floppy
- Make sure to choose a compatible-with-it PCnet-FAST III (Am79C973) Network Controller

## Footprint

- Floppy: 2880KiB / 2.88MiB
- Kernel: 2205KiB _(bzImage-ath/bzImage-pcn)_ --- 2209KiB _(bzImage-rtl)_
- Rootfs: ~470KiB _(rootfs-ath.cpio.lzma/rootfs-pcn.cpio.lzma)_ --- ~479KiB _(rootfs-rtl.cpio.lzma)_
- Free space left _(df -B 1)_: **flpnxath.img/flpnxpcn.img - 17 KiB, flpnxrtl.img - almost 0 KiB**

## Features

- Architecture changes
  - 2.88 MB floppy image for AMD x86_64 PCs _(works fine in VirtualBox too)_, with many AMD-specific features enabled
  - Enabled kexec features, so after booting this floppy and running `/etc/get_repo.sh` - you can wget an advanced kernel/rootfs and "switch" to it, i.e. `./slitaz.sh`
  - Disabled Intel CPU support to save space, but you may re-enable it at the cost of something else and use this distro on your Intel
  - Disabled microcode loading: thanks to opensource coreboot BIOS I do not need this space-taking feature at my Linux kernel
  - Disabled physical floppy drive support _(ISA-style DMA support aka `ISA_DMA_API`)_: desperately needed more extra space
  - Disabled printk in order to win even more space, to re-enable it for debugging you will have to disable the other features
- Device support
  - Ethernet - the exact supported Ethernet controller model depends on a floppy version:
    - Qualcomm/Atheros AR8161/AR8162/QCA8171/QCA8172 ([flpnxath.img](https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/floppies/flpnxath.img)) - found in coreboot-supported AMD Lenovo G505S - the most powerful no-ME/no-PSP coreboot laptop
    - Realtek RTL8111/RTL8168/RTL8169/RTL8101/RTL8125 ([flpnxrtl.img](https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/floppies/flpnxrtl.img)) - found in coreboot-supported ASUS A88XM-E & AM1I-A desktops and dirt cheap PCIe Ethernet cards
    - AMD PCnet-FAST III Am79C973/79C971 ([flpnxpcn.img](https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/floppies/flpnxpcn.img)) - could be selected in VirtualBox settings if you would like to try out this floppy distribution there
    - Intel PRO/1000 PCI-Express 82574L _(too fat, so no `flpnxint.img` yet)_ - found in coreboot-supported ASUS KGPE-D16 - the most powerful no-ME/no-PSP coreboot/libreboot server
  - WiFi
    - Atheros ath9k family of PCIe WiFi adapters, such as AR9462 that works on 100% opensource without any firmware
    - Atheros ath9k_htc family of USB WiFi adapters, such as AR9271 that seems to need a firmware for unknown reasons
  - USB
    - EHCI (USB 2.0) / OHCI (USB 1.1) support, essential for using the USB WiFi adapters as well as the input devices
    - SCSI and USB storage support is enabled, so you can write the files to a FAT-formatted (old FAT) USB flash drive
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
  - OpenSSL
    - A standalone executable binary for this cryptography and SSL/TLS toolkit
  - Links
    - This text-based web browser lets you browse some relatively-simple websites

Also, I have fixed many bugs like a frozen ping _(had to enable timer-related features)_ and Ctrl+C/Ctrl+Z interrupts _(changes related to TTY and job control)_.

## Kernel Configuration

We get the sources for the latest compatible **kernel 6.18.18**, replace the non-0 optimization flags with `-Oz` for an aggressive size optimization, then build this kernel in three variants using a `linux-XXX.cfg` that we wget from this repository. The following common options have been chosen on top of the bare minimum `make ARCH="x86_64" tinyconfig`:

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
  - Kexec and crash features
    - Enable kexec system call: CONFIG_KEXEC
    - Enable kexec file based system call: CONFIG_KEXEC_FILE
- Bus options
  - Original instruction: ISA-style DMA support: ISA_DMA_API (for ARCH_MAY_HAVE_PC_FDC for CONFIG_BLK_DEV_FD)
  - My instruction: do not enable this option to save a lot of space if we do not use a physical floppy drive
- Enable the block layer: CONFIG_BLOCK
- Executable file formats
  - Kernel support for ELF binaries: CONFIG_BINFMT_ELF
  - Kernel support for scripts starting with #!: CONFIG_BINFMT_SCRIPT
- Memory Management options
  - Disable "Support for paging of anonymous memory (swap)": CONFIG_SWAP
  - Enable memfd_create() system call: MEMFD_CREATE
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
  - SCSI device support
    - SCSI device support: CONFIG_SCSI
      - SCSI disk support: CONFIG_BLK_DEV_SD
      - Disable "SCSI low-level drivers": SCSI_LOWLEVEL
  - USB support: CONFIG_USB_SUPPORT
    - Support for Host-side USB: CONFIG_USB
      - EHCI HCD (USB 2.0) support: CONFIG_USB_EHCI_HCD
      - OHCI HCD (USB 1.1) support: CONFIG_USB_OHCI_HCD
    - USB Mass Storage support: CONFIG_USB_STORAGE
  - Network device support: CONFIG_NETDEVICES
    - Disable "Network core driver support": CONFIG_NET_CORE
    - Ethernet driver support: CONFIG_ETHERNET
      - **Uncheck everything there before proceeding, then select only one of these adapters**
      - AMD devices: CONFIG_NET_VENDOR_AMD
        - AMD PCnet32 PCI support: CONFIG_PCNET32 _(for a "VirtualBox" bzImage-pcn only)_
      - Atheros devices: CONFIG_NET_VENDOR_ATHEROS
        - Qualcomm Atheros AR816x/AR817x support: CONFIG_ALX _(for "AMD Lenovo G505S" bzImage-ath only)_
      - Intel devices: CONFIG_NET_VENDOR_INTEL
        - Intel(R) PRO/1000 PCI-Express Gigabit Ethernet support: CONFIG_E1000E _(too fat, so no "ASUS KGPE-D16" bzImage-int yet)_
          - Disable "Support HW cross-timestamp on PCH devices": CONFIG_E1000E_HWTS (too fat, so no "ASUS KGPE-D16" bzImage-int yet)_
        - Disable "Intel (82586/82593/82596) devices": CONFIG_NET_VENDOR_I825XX _(too fat, so no "ASUS KGPE-D16" bzImage-int yet)_
      - Realtek devices: CONFIG_NET_VENDOR_REALTEK
        - Realtek 8169/8168/8101/8125 ethernet support: CONFIG_R8169 (also supports 8111) _(for "ASUS A88XM-E / AM1I-A" bzImage-rtl only)_
    - Wireless LAN: CONFIG_WLAN
      - **Uncheck everything there before proceeding**
      - Atheros/Qualcomm devices: CONFIG_WLAN_VENDOR_ATH
        - Atheros 802.11n wireless cards support: CONFIG_ATH9K
        - Disable "Atheros bluetooth coexistence support": CONFIG_ATH9K_BTCOEX_SUPPORT (we did not enable the Bluetooth of AR9462 card)
        - Atheros ath9k ACK timeout estimation algorithm: CONFIG_ATH9K_DYNACK
      - Atheros HTC based wireless cards support: CONFIG_ATH9K_HTC
  - Input device support
    - Generic input layer (needed for keyboard, mouse, ...): CONFIG_INPUT
      - Disable "Mice": CONFIG_INPUT_MOUSE
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
    - VFAT (Windows-95) fs support: CONFIG_VFAT_FS
    - Enable FAT UTF-8 option by default: CONFIG_FAT_DEFAULT_UTF8
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

## Busybox Toolset

We get the sources for the latest compatible **busybox 1.37.0**, replace the `-O2` optimization flags with `-Os` for a size optimization _(musl.cc toolchain's GCC is too old for `-Oz`)_, then build this busybox and generate a rootfs filesystem with it in two variants: with Realtek firmware binaries that might be needed for "ASUS A88XM-E / AM1I-A" `(rootfs-wirtl.cpio.lzma)` and without them for the other boards `(rootfs-nortl.cpio.lzma)`. The following common options have been chosen on top of the bare minimum `make ARCH="x86_64" allnoconfig`:

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
    - Disable "Support weird 'date MMDDhhmm[[YY]YY][.ss]' format": CONFIG_FEATURE_DATE_COMPAT
  - df: CONFIG_DF
    - Disable "Skip rootfs in mount table": CONFIG_FEATURE_SKIP_ROOTFS
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
    - Disable "Support regular expressions substitutions when renaming device": CONFIG_FEATURE_MDEV_RENAME_REGEXP
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
    - Disable "Enable slip-specific options "keepalive" and "outfill"": CONFIG_FEATURE_IFCONFIG_SLIP
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

## Included Software

### File & Directory Manipulation
- `cat` - concatenate files and print on standard output
- `chmod` - change file mode bits
- `cp` - copy files and directories
- `ln` - create hard and symbolic links
- `ls` - list directory contents
- `mkdir` - create directories
- `mv` - move (rename) files
- `pwd` - print current working directory
- `rm` - remove files or directories

### System Information & Management
- `date` - print or set system date and time
- `df -h` - display filesystem disk space usage in human-readable format
- `free` - display amount of free and used memory
- `init` - init process (PID 1)
- `lsusb` - list USB devices
- `lspci` - list PCI devices
- `mount` - mount filesystems
- `sync` - flush filesystem buffers (use after modifying files on removable media)
- `umount` - unmount filesystems
- `uptime` - system uptime and load average

### Device Management
- `mdev` - minimal device manager (hotplug)

### Text Processing & Output
- `echo` - display a line of text

### Process Control
- `kill` - terminate a process
- `ps` - report process status
- `setsid` - run a program in a new session
- `sleep` - delay for a specified time
- `timeout` - run a command with a time limit

### Networking Utilities
- `ifconfig` - configure network interfaces
- `ifplugd` - detect network cable plug events
- `ping` - send ICMP ECHO_REQUEST to hosts
- `route` - show/manipulate IP routing table
- `scp` (dropbear) - secure remote file copy
- `ssh` (dropbear) - secure shell client and server
- `udhcpc` - DHCP client
- `wget` - retrieve files via HTTP/HTTPS/FTP
- `wpa_cli` - command-line interface for wpa_supplicant
- `wpa_supplicant` - WPA/WPA2 authentication daemon for WiFi networks

### Utilities
- `beep` - beep the PC speaker
- `clear` - clear the terminal screen
- `cttyhack` - hack to set controlling terminal
- `test` - evaluate conditional expressions (also available as `[` and `[[`)

### Applications
- `vi` - text editor
- `ash` - Almquist shell (command interpreter)

### Additional Tools (downloaded via /etc/get_repo.sh)
- `kirc` - IRC client
- `links` - Web browser
- `openssl` - cryptography and SSL/TLS toolkit

## Support the Project

### 💝 Donate to the original project's author

FLOPPINUX is a free and open-source project. If you find it useful and want to support its development, consider making a donation to the original project's author _(personally I do not accept the donations yet)_. Your support helps maintain the project and develop new features.

**[💖 Support via Liberapay](https://liberapay.com/w84death/)**

Every contribution, no matter how small, is appreciated! 🙏

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
**2026.03**  
