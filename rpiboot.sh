# This would definately be better to do inside the docker container itsself, but oh well.

bash build.sh;

if [ -d /Volumes/rpialpine ]; then
    echo "Disk image already mounted on /Volumes/rpialpine";
    exit 1;
fi

pushd workdir;
pushd output;
TARNAME=$(ls *.tar.gz);
tar xvf $TARNAME;
rm $TARNAME;


SYSTEM_IP=$(ifconfig | grep -e "inet 192.168." -e "inet 10." -e "inet 172.1" | sed 's/.*inet //; s/ netmask.*//' | tail -n 1)
echo "Assuming the Pi can reach this system at $SYSTEM_IP"

echo "modules=loop,squashfs" \
     "ip=dhcp" \
     "modloop=http://$SYSTEM_IP:4444/boot/modloop-rpi" \
     "alpine_repo=http://$SYSTEM_IP:4444/apks" \
     "apkovl=http://$SYSTEM_IP:4444/rpi.apkovl.tar.gz" > cmdline.txt

popd;

if [ -n "$RPIBOOT_BUILDIMG" ]; then
    dd if=/dev/zero of=boot.img bs=1k count=100000;
    DISK=$(hdiutil attach -nomount boot.img);

    SAFETY=$(diskutil list | grep $DISK | head -n 1 | grep "disk image");
    if [ -z "$SAFETY" ]; then
        echo "Disk image not found on $DISK";
        exit 1;
    fi

    diskutil erasedisk fat32 rpialpine mbr $DISK;
    cp -r output/* /Volumes/rpialpine/;
    diskutil unmountDisk $DISK;
    hdiutil detach $DISK;

    mkdir rpiboot;

    mv ./boot.img rpiboot/;
    cp ./output/bootcode.bin rpiboot/;
    cp ./output/start*.elf rpiboot/;
    echo "boot_ramdisk=1" > rpiboot/config.txt;
    rpiboot -d rpiboot;
else 
    echo "If you're using a Pi 4+, consider setting RPIBOOT_BUILDIMG for a more reliability during booting.";
    rpiboot -d output;

fi

pushd output;
php -S 0.0.0.0:4444
popd;
popd;


