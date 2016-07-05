#!/bin/bash
#Arch Linux ARM for Orange Pi PC
#My use of OPI products does not constitute an endorsement of the company or its policies or its methods of interacting with the OSS community.  
#It should instead speak to the unavailablity of better at smiliar price.  

set -x
export PATH=$PATH:/home/faddat/projects/orangearches/gcc-linaro-5.3-2016.02-x86_64_arm-linux-gnueabihf/bin
export PROJECTROOT=$(pwd)
export BUILDTIME=$(date +%T)
rm -rf boot/*


echo "[INFO] Creating u-boot"
if [ ! -d u-boot ]; then
        git clone git://github.com/u-boot/u-boot
elif [ -d u-boot ]; then
        cd u-boot 
        git pull
        cd ..
fi

cd u-boot 
CROSS_COMPILE=arm-linux-gnueabihf- make orangepi_pc_config 
CROSS_COMPILE=arm-linux-gnueabihf- make 
cp u-boot-sunxi-with-spl.bin ../boot/u-boot-sunxi-with-spl.bin
cd ..

echo "[INFO] Creating Boot zImage"
if [ ! -d linux ]; then
		git clone https://github.com/faddat/orangepipc-linux linux 
		cd linux 
		make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- 
        cp arch/arm/boot/dts/sun8i-h3-orangepi-pc.dtb ../boot/sun8i-h3-orangepi-pc.dtb
        cp arch/arm/boot/zImage ../boot/zImage
        cd ..
elif [ -d u-boot ]; then
		cd linux 
		git pull https://github.com/faddat/orangepipc-linux 
		cp OPIPC_TEST_CONFIG .config 
		make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-
		cp arch/arm/boot/dts/sun8i-h3-orangepi-pc.dtb ../boot/sun8i-h3-orangepi-pc.dtb 
        cp arch/arm/boot/zImage ../boot/zImage
        cd ..
fi

cp boot.cmd boot/boot.cmd
cd boot
ls
mkimage -C none -A arm -T script -d boot.cmd boot.scr 
cd ..

echo "[INFO] Allocating image space"
#Makes the Image File
dd if=/dev/zero of=orangepiarch.img bs=1M count=2048
#Mounts as a loopback device
losetup /dev/loop0 orangepiarch.img
#Creates the partition
BOOTSTART
parted -s orangepiarch.img -- mkpart primary ext4 2048s -1s
partprobe /dev/loop0


#formats the partitions
mkfs.ext4 /dev/loop0p1
sudo dd if=u-boot/u-boot-sunxi-with-spl.bin of=/dev/loop0 bs=1024 seek=8
sync
mount /dev/loop0 /partition1
sync

echo "[INFO] Copying rootfs"
if [ ! -f ArchLinuxARM-armv7-latest.tar.gz ]; then
        wget http://os.archlinuxarm.org/os/ArchLinuxARM-armv7-latest.tar.gz
fi
bsdtar -C /partition1 -xzf ArchLinuxARM-armv7-latest.tar.gz
sync
mkdir /partition1/boot
cp boot/* /partition1/boot

echo "[INFO] Creating /proc, /sys, /mnt, /tmp & /boot"
sudo mkdir -p /partition1/proc
sudo mkdir -p /partition1/sys
sudo mkdir -p /partition1/mnt
sudo mkdir -p /partition1/tmp
sudo mkdir -p /partition1/boot
sync

umount /partition1
sync
sudo losetup -d /dev/loop0

