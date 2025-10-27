Device Drivers → Graphics Support:**
- [x] Support for frame buffer devices
- [x] VESA VGA graphics support
- [x] Framebuffer Console support (optional, but nice for debugging


Add the framebuffer device to your filesystem creation script:

```
cd filesystem
sudo mknod dev/fb0 c 29 0
sudo chown root:root dev/fb0
```


Compile
```
fasm pixel.asm pixel
```

```
$ file pixel
pixel: ELF 32-bit LSB executable, Intel 80386, version 1 (GNU/Linux), statically linked, no section header
```

Make it executable (if needed)
```
chmod +x pixel
```
Copy to your FLOPPINUX filesystem
```
cp pixel filesystem/bin/
```

Run it in QEMU
```
qemu-system-i386 -fda floppinux.img -m 20M -cpu 486 -vga std
```
