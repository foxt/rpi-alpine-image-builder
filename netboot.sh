set -e

PC_STATIC_IP=192.168.3.2
PC_STATIC_SUBNET=255.255.255.240
DHCP_RANGE="192.168.3.3,192.168.3.10"

DNSMASQ=dnsmasq
if [ -f "/opt/homebrew/opt/dnsmasq/sbin/dnsmasq" ]; then
    DNSMASQ="/opt/homebrew/opt/dnsmasq/sbin/dnsmasq";
fi

APPDIR=$(dirname "$0")
WORKDIR=$APPDIR/workdir
OUTDIR=$WORKDIR/output
TEMP=$(mktemp -d)
INTF=$1

if [ -z "$INTF" ]; then
    echo "Usage: $0 <interface>"
    echo "interface: interface that the Pi is connected to (e.g. en0, eth1)."
    echo "The Pi should be connected directly to this system via an Ethernet cable."
    echo "Do **NOT** specify any network interface with other devices connected to it."
    echo "A static IP address will be assigned on this interface and a DHCP server will be started."
    echo "The script will try to change the IP address of the interface back to DHCP when it exits."
    echo "So, if you have a static IP address on this interface, please take note of it."
    exit 1
fi
if ifconfig $INTF; then
    echo "Using $INTF."
else
    echo "Interface $INTF does not exist."
    exit 1
fi

TARNAME=$(ls $OUTDIR/alpine-*.tar.gz)
if [ -z "$TARNAME" ]; then
    echo "No image found in $OUTDIR. (did you run build.sh?)"
    exit 1
fi
echo "Extracting the image..."
# Extract the image
tar xvzf $TARNAME -C $TEMP
chmod -R 644 $TEMP

# Set up the network
echo "Setting up the network..."
ifconfig $INTF
ifconfig $INTF $PC_STATIC_IP netmask $PC_STATIC_SUBNET
trap "pkill dnsmasq; ipconfig set $INTF dhcp; rm -rf $TEMP" EXIT

# Tell the Pi where to get the system packages
echo "modules=loop,squashfs" \
     "console=serial0,115200" \
     "ip=dhcp" \
     "modloop=http://$PC_STATIC_IP:4444/boot/modloop-rpi" \
     "alpine_repo=http://$PC_STATIC_IP:4444/apks" \
     "apkovl=http://$PC_STATIC_IP:4444/rpi.apkovl.tar.gz" > $TEMP/cmdline.txt
echo "enable_uart=1" >> $TEMP/config.txt


echo "Starting the DHCP server..."
$DNSMASQ -d \
    --log-facility - --log-dhcp \
    -i $INTF \
    --dhcp-range=$DHCP_RANGE,30 \
    --pxe-service=0,"Raspberry Pi Boot   " \
    --enable-tftp --tftp-root=$TEMP &
DNSMASQ_PID=$!

echo "Starting the web server..."
php -S 0.0.0.0:4444 -t $TEMP 
