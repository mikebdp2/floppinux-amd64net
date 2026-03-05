# FLOPPINUX-AMD64NET 💾

**An Embedded 🐧Linux on a Single 💾Floppy**

## 🛠️ FLOPPINUX 2026 Workshop (v0.3.1-amd64net) 🛠️

**OUTDATED , PLEASE JUST TAKE A LOOK AT FLOPPINUX-AMD64NET.SH MEGASCRIPT FOR A WHILE [Complete tutorial to build your own FLOPPINUX-AMD64NET from scratch](floppinux.md)**

**This is a modified floppinux "amd64net" distribution. It is primarily aimed for embedding as a virtual floppy into the opensource coreboot BIOS of supported AMD PCs ( more information here - http://dangerousprototypes.com/docs/Lenovo_G505S_hacking ), however it may be used for other needs as well. Main features:**

- Architecture changes
  - 2.88 MB floppy image for AMD PCs of x86_64 architecture (seems to work fine in VirtualBox too), with many AMD-specific features enabled
  - Intel CPU support is disabled to save space, however you may re-enable it at cost of something else and use this distro on your Intel
  - Microcode loading is disabled because thanks to opensource coreboot BIOS I do not need this space-taking feature at my Linux kernel
  - Physical floppy drive support (ISA-style DMA support aka ISA_DMA_API) is disabled in Linux kernel too because I needed some extra space
  - Had to disable printk in order to win even more space, to re-enable it for debugging you will have to temporarily disable the other features
- Device support
  - Ethernet (exact supported Ethernet depends on a floppy version)
    - AMD PCnet-FAST III Am79C973/79C971 - could be selected in a VirtualBox settings if you would like to try out this floppy distribution there
    - Qualcomm/Atheros AR8161/AR8162/QCA8171/QCA8172 - found in coreboot-supported AMD Lenovo G505S - the most powerful no-ME/no-PSP coreboot laptop
    - Realtek RTL8111/RTL8168/RTL8169/RTL8101/RTL8125 - found in coreboot-supported ASUS A88XM-E & AM1I-A desktops and dirt cheap PCIe Ethernet cards
    - Intel PRO/1000 PCI-Express 82574L - found in coreboot-supported ASUS KGPE-D16 - the most powerful no-ME/no-PSP coreboot/libreboot server
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

Also, I have fixed many bugs like a frozen ping _(had to enable timer-related features)_ and Ctrl+C/Ctrl+Z interrupts _(changes related to TTY and job control)_.

**The instructions above are originally provided by @w84death and have been heavily modded by me (Mike Banon) for this "amd64net" distribution.**

> FLOPPINUX is a complete Linux distribution that fits on a single 2.88MB floppy disk. Think of it as Linux From Scratch but for making single floppy distribution. It boots directly into a working Linux terminal with persistent storage and essential tools.

## What is FLOPPINUX?

FLOPPINUX is a fully functional Linux distribution designed to run on minimal hardware. It supports all 32-bit x86 CPUs since Intel 486DX and requires only 20MB of RAM. Perfect for reviving old hardware, embedded systems, or educational purposes.

### Key Features:

- 💾 Fits on a single 1.44MB floppy disk
- 🐧 Latest Linux kernel (6.14.11) with i486 support
- 📝 Vi text editor and essential file manipulation tools
- 💾 264KB persistent storage for your files
- ⚙️ Works on real hardware and emulation
- 🔧 Fully customizable and hackable

### Minimum Hardware Requirements:

- Intel 486DX 33MHz processor
- 20MB RAM
- 3.5" floppy disk drive

## Resources & Downloads

- **Latest Release:** [FLOPPINUX - Floppy Image (1.44MB)](floppinux.img)
- **Source Code:** [GitHub Repository](https://github.com/w84death/floppinux)
- **Workshop/tutorial:** [MD](floppinux.md) [ePub](floppinux.epub) [Online HTML](https://krzysztofjankowski.com/floppinux/floppinux-2025.html)
<!--- **Archive Mirror:** [Internet Archive](https://archive.org/details/floppinux_0.3.1)-->

## Articles & Tutorials

- **[FLOPPINUX 2025 Update (v0.3.1)](https://krzysztofjankowski.com/floppinux/floppinux-2025.html)** 🆕
- [Original FLOPPINUX Tutorial (2021)](https://krzysztofjankowski.com/floppinux/floppinux-an-embedded-linux-on-a-single-floppy.html)
- [Creating Sample Applications for FLOPPINUX](https://krzysztofjankowski.com/floppinux/sample-application.html)
- [Building 32-bit FLOPPINUX on 64-bit Systems](https://krzysztofjankowski.com/floppinux/how-to-build-32-bit-floppinux-on-a-64-bit-os.html)
- [FLOPPINUX in the Wild - Community Showcase](https://krzysztofjankowski.com/floppinux/floppinux-in-the-wild.html)

## Community & Discussion

Version 3.0:

- **[Can Modern Linux Fit on a 1.44mb Floppy?
](https://www.youtube.com/watch?v=SiHZbnFrHOY)** by Action Retro
- **[Alternative DMF Floppy Layout](dmf-layout.md)** by [dscp46](https://github.com/dscp46)
- [Linux On A Floppy: Still (Just About) Possible
](https://hackaday.com/2025/12/20/linux-on-a-floppy-still-just-about-possible/) hackaday.com
- [Someone ran a modern-day Linux distro off a floppy disk, and it looks more fun than it should be](https://www.xda-developers.com/someone-ran-a-modern-day-linux-distro-off-a-floppy-disk-and-it-was-more-fun-than-it-should-be/) xda-developers.com

Version up to 2.1:
- [Hacker News Discussion](https://news.ycombinator.com/item?id=27247612)
- [HackADay Feature](https://hackaday.com/2021/05/24/running-modern-linux-from-a-single-floppy-disk/)
- [Hackster.io Article](https://www.hackster.io/news/floppinux-places-a-compact-form-of-linux-on-a-floppy-disk-3f5fdab432b0)
- [Adafruit Blog Post](https://blog.adafruit.com/2021/05/27/floppinux-an-embedded-linux-on-a-single-floppy-linux-w84death/)
- [Mastodon Discussion](https://mastodon.social/web/statuses/106257685960283225)
- Community Fork: [GitLab](https://gitlab.com/clark_electric/floppinux) | [Video Demo](https://www.youtube.com/watch?v=m5bjI7HoQ50)

## Support the Project

### 💝 Donate

FLOPPINUX is a free and open-source project. If you find it useful and want to support its development, consider making a donation. Your support helps maintain the project and develop new features.

**[💖 Support via Liberapay](https://liberapay.com/w84death/)**

Every contribution, no matter how small, is appreciated! 🙏

---

```
                         _________________
                        /_/ FLOPPINUX  /_/;
                       / ' boot disk  ' //
                      / '------------' //
                     /   .--------.   //
                    /   /         /  //
                   .___/_________/__//   1440KiB
                   '===\_________\=='   3.5"


               Now go and make something fun with it!
```

**Homepage:** https://krzysztofjankowski.com/floppinux/
