#!/bin/sh
sudo rm -rf ./filesystem/
cp -r ./busybox/_install/ ./filesystem/
cd ./filesystem/
mkdir -pv {dev,proc,etc/init.d,sys,tmp,home,var/run,lib/firmware/ath9k_htc,lib/firmware/rtl_nic}
sudo mknod ./dev/console c 5 1
sudo mknod ./dev/null c 1 3
wget https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/welcome
cat >> ./etc/inittab << EOF
::sysinit:/etc/init.d/rc
::askfirst:/usr/bin/setsid /bin/cttyhack /bin/sh
::respawn:/usr/bin/setsid /bin/cttyhack /bin/sh
::restart:/sbin/init
::ctrlaltdel:/sbin/reboot
::shutdown:/bin/umount -a -r
EOF
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
cat >> ./etc/wpa_supplicant.conf << EOF
ctrl_interface=/var/run/wpa_supplicant
update_config=1
EOF
cat >> ./etc/get_kirc.sh << EOF
wget https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/kirc
wget https://raw.githubusercontent.com/mikebdp2/floppinux-amd64net/refs/heads/main/kirc.txt
chmod +x ./kirc
EOF
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
rm -f ./../rootfs.cpio
rm -f ./../rootfs.cpio.lzma
find . -print0 | LC_ALL="C" sort -z | cpio -0 -H newc -o --reproducible 2>/dev/null > ./../rootfs.cpio
strip-nondeterminism -t cpio -T 1770768000 ./../rootfs.cpio
xz --threads=1 --format=lzma --check=crc32 --lzma1=dict=64MiB,lc=3,lp=0,pb=2,mode=normal,nice=273,mf=bt4,depth=0 < ./../rootfs.cpio > ./../rootfs.cpio.lzma
rm -f ./../rootfs.cpio
cd ./../
ls -al ./rootfs.cpio.lzma