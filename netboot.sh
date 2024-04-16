set -e
bash build.sh
if [ ! -f /System/Library/LaunchDaemons/tftp.plist ]; then
    echo "tftpd is not installed on this system -- currently this script only supports macOS"
    exit 1
fi
if [ -z "$PI_SERIAL" ]; then
    echo "PI_SERIAL is not set. Please set it to the serial number of the Raspberry Pi you want to netboot."
    echo "You can find the serial number by connecting the Raspberry Pi to a HDMI display with no SD card inserted."
    echo "The serial number will be displayed in the top left corner of the screen, for example if the Pi displays:"
    echo " board: c03112 abcdefgh aa:bb:cc:dd:ee:ff"
    echo " the serial number is abcdefgh"
    exit 1
fi

cd workdir/output
tar xvf *.tar.gz

SYSTEM_IP=$(ifconfig | grep -e "inet 192.168." -e "inet 10." -e "inet 172.1" | sed 's/.*inet //; s/ netmask.*//' | tail -n 1)
echo "Assuming the Pi can reach this system at $SYSTEM_IP"

echo "modules=loop,squashfs" \
     "console=serial0,115200" \
     "ip=dhcp" \
     "modloop=http://$SYSTEM_IP:4444/boot/modloop-rpi" \
     "alpine_repo=http://$SYSTEM_IP:4444/apks" \
     "apkovl=http://$SYSTEM_IP:4444/rpi.apkovl.tar.gz" > cmdline.txt
echo "enable_uart=1" >> config.txt


sudo rm -rf /private/tftpboot/$PI_SERIAL
sudo mkdir -p /private/tftpboot/$PI_SERIAL
sudo cp -r ./* /private/tftpboot/$PI_SERIAL
sudo chmod -R 777 /private/tftpboot/$PI_SERIAL

sudo launchctl load -F /System/Library/LaunchDaemons/tftp.plist

php -S 0.0.0.0:4444
