# DMF Floppy Alternative Layout

Made by [dscp46](https://github.com/dscp46)

## Introduction
I've been able to produce superformatted images that run both on Virtualbox and on physical machines
For some reason, when run on Qemu, syslinux fails on stage 2 (last displayed line is `SYSLINUX 6.04 CHSBoot error`).

The largest bootable layout I've found is the 83/2/21 layout: 83 cylinders, 2 heads, 21 sectors. 
The DMF layout (80 cyl, 2 hds, 21 sects, 4 sectors/cluster) is a safer alternative.
We can shave extra space by setting 4 sectors per cluster, and a root directory of 4 sectors. Avoid adding too many files in the root directory.

Hardest part is to produce the syslinux bootable skeleton.

Here are some stats (I've added a few things, don't pay too much attention to the size of my bzimage and rootfs):

83/2/21 layout:
```
 Volume in drive : is FLOPPINUX  
 Volume Serial Number is 1701-0362
Directory for ::/

ldlinux  sys     59392 2025-12-11  10:53 
ldlinux  c32    119532 2025-12-11  10:53 
SYSLINUX CFG       160 2025-12-11  15:56  syslinux.cfg
BZIMAGE         868864 2025-12-11  15:56  bzImage
ROOTFS~1 XZ     165344 2025-12-11  15:56  rootfs.cpio.xz
DATA         <DIR>     2025-12-11  15:56  data
        6 files           1 213 292 bytes
                            555 008 bytes free
```

DMF layout:
```
 Volume in drive : is FLOPPINUX  
 Volume Serial Number is 26B4-D417
Directory for ::/

ldlinux  sys     59392 2025-12-11  10:15 
ldlinux  c32    119532 2025-12-11  10:15 
SYSLINUX CFG       160 2025-12-11  15:27  syslinux.cfg
BZIMAGE         868864 2025-12-11  15:27  bzImage
ROOTFS~1 XZ     165332 2025-12-11  15:27  rootfs.cpio.xz
DATA         <DIR>     2025-12-11  15:27  data
        6 files           1 213 280 bytes
                            491 520 bytes free
```


> [!CAUTION]
> Superformatted images can't be manipulated with USB FDD drives, due to limitations in the [USB Floppy Interface model](https://web.archive.org/web/20130430042731/http://www.usb.org/developers/devclass_docs/usbmass-ufi10.pdf).

---- 
# Baking a syslinux-bootable superformatted skeleton
## Use a pre-baked skeleton

The files `dmf_blank.img` and `1743_blank.img` are attached to this ticket for your convenience if you don't want to bother with this step. Don't forget to `gunzip` them.

 - [1743_blank.img.gz](https://github.com/user-attachments/files/24107361/1743_blank.img.gz)
 - [dmf_blank.img.gz](https://github.com/user-attachments/files/24105946/dmf_blank.img.gz)

## With a virtual machine
> [!NOTE]
> Tested with VirtualBox. Qemu not being able to boot the final images, I didn't try testing it against this procedure.

First, you need to generate your blank image:
| Layout | Command |
| --- | --- |
| 83/2/21 | `dd if=/dev/zero of=floppinux.img bs=512 count=3486` |
| DMF | `dd if=/dev/zero of=floppinux.img bs=512 count=3360` |

Attach it to a VM, alongside a live CD that ships mformat and syslinux (I did it with damn small linux 2024).

Once your system is booting run the following:

### 83/2/21 layout
```bash
[ ! -b /dev/fd0u1743 ] && sudo mknod /dev/fd0u1743 b 2 76
sudo mformat -t 83 -h 2 -s 21 -r 4 -c 4 -v FLOPPINUX a:
sudo syslinux -s /dev/fd0u1743
```

### DMF layout
```bash
[ ! -b /dev/fd0u1680 ] && sudo mknod /dev/fd0u1680 b 2 44
sudo mformat -t 80 -h 2 -s 21 -r 4 -c 4 -v FLOPPINUX a:
sudo syslinux -s /dev/fd0u1680
```

You can now shut your VM down.

## With a physical floppy drive (won't work with USB floppy drives)
With this method, you will first appropriately format a floppy, set the filesystem, install syslinux, then create an image.

### 83/2/21 Layout
```
[ ! -b /dev/fd0u1743 ] && sudo mknod /dev/fd0u1743 b 2 76
sudo fdformat /dev/fd0u1743
sudo mformat -t 83 -h 2 -s 21 -r 4 -c 4 -v FLOPPINUX a:
sudo syslinux -s /dev/fd0u1743
sudo dd if=/dev/fd0u1743 of=floppinux.img bs=512
```
### DMF Layout
```
[ ! -b /dev/fd0u1680 ] && sudo mknod /dev/fd0u1680 b 2 44
sudo fdformat /dev/fd0u1680
sudo mformat -t 80 -h 2 -s 21 -r 4 -c 4 -v FLOPPINUX a:
sudo syslinux -s /dev/fd0u1680
sudo dd if=/dev/fd0u1680 of=floppinux.img bs=512
```

# Filesystem corrections 
After running
```
mkdir -pv {dev,proc,etc/init.d,sys,tmp,home}
sudo mknod dev/console c 5 1
sudo mknod dev/null c 1 3
```
You'll need to run the following:
| Layout | Command |
| --- | --- |
| 83/2/21 | `sudo mknod /dev/fd0u1743 b 2 76` |
| DMF | `sudo mknod /dev/fd0u1680 b 2 44` |

In the `etc/init.d/rc` script, replace `mount -t msdos -o rw /dev/fd0 /mnt` by the following:
| Layout | Command |
| --- | --- |
| 83/2/21 | `mount -t msdos -o rw /dev/fd0u1743 /mnt` |
| DMF | `mount -t msdos -o rw /dev/fd0u1680 /mnt` |

## Formatting a floppy
Your target floppy needs to low-level formatted to your desired layout prior proceeding further.
You need to run the commands below once.
 
### 83/2/21 Layout
```
[ ! -b /dev/fd0u1743 ] && sudo mknod /dev/fd0u1743 b 2 76
sudo fdformat /dev/fd0u1743
```

### DMF Layout
```
[ ! -b /dev/fd0u1680 ] && sudo mknod /dev/fd0u1680 b 2 44
sudo fdformat /dev/fd0u1680
```

### Standard layout
Once you're done with your test, here is the command to format back your floppy to the standard layout:
```
sudo fdformat /dev/fd0
```

## Writing your image to a floppy

| Layout | Command |
| --- | --- |
| 83/2/21 | `sudo dd if=floppinux.img of=/dev/fd0u1743 bs=512 conv=notrunc,sync,fsync oflag=direct status=progress` |
| DMF | `sudo dd if=floppinux.img of=/dev/fd0u1680 bs=512 conv=notrunc,sync,fsync oflag=direct status=progress` |  