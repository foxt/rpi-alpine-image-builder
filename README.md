# Raspberry Pi Alpine Image Builder

This is a rudimentary script to build a custom Alpine Linux image for the Raspberry Pi. The goals of this project are:
  - Build a custom ramdisk based OSimage for the Raspberry Pi 
  - Entirely built on a workstation - i.e. not: put a fresh SD card in the Pi to modify an existing image
  - Built in a 'clean-room' fashion - booting an Alpine image and immediately running `lbu commit` shows that changes are made to the system during the boot process, and can be based on unique configuration (for example, /etc/resolv.conf is filled in with the DNS server & hostname from DHCP).
  - Netboot and or rpiboot for ease of development.
   

## Process
As Alpine must be built on Alpine, an ephemeral Docker container is used to run the build scripts. The scripts clones the [aports](https://gitlab.alpinelinux.org/alpine/aports) repo and uses custom `mkimg` and `genapkovl` profiles to generate a `tar.gz` folder which can be extracted to the root of a FAT32 SD card and inserted into the Pi.

Booting from the network or via [rpiboot](https://github.com/raspberrypi/usbboot) is possible, however is a little bit more involved, as:

    - Neither netboot or rpiboot can only deliver the Linux kernel and initramfs, for the APKs, modloop & apkovl, these must be delivered via HTTP or FTP.
      - This also means that both netboot and rpiboot require the Raspberry Pi to be connected via an Ethernet connection, thus, meaning this cannot be performed on the Zero or the Pi 3A.
      - It may be possible to include `wpa_supplicant` into the initramfs to allow rpiboot to work on the Zero over Wifi, USB ethernet for the 1A/3A and CM1/3/3+/4S. More investigation is needed.
    - Netboot requires a SFTP server to deliver the files.
    - On Pi 4 and 5, the SFTP server IP address can be [configured in the EEPROM](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#TFTP_IP). On the Pi3, this must be handed out by the DHCP server.
    - A script is provided for macOS users to allow network booting using the built in tftp server.
    - A script is also included for macOS users to use rpiboot. This must be installed separately. TODO: convert the `boot.img` generation script to a Linux script for use in the Docker container.

## Configurations


### Image architecture
| Model                  | aarch64 | armv7 | armhf | Notes |
|------------------------|---------|-------|-------|-------|
| Pi 5                   |   ❔    |   👎  |   👎  | |
| Pi 4/CM4/CM4S/400      |   ✅    |   🔥  |   🔥  | Tested on a Pi 4 (v1.2) 4GB. |
| Pi 3/3+/CM3/CM3+/Zero2 |   ✅    |   ✅  |   🔥  | Tested on a Pi 3B 1.2 and a Pi Zero 2W |
| Pi 2B                  |   👎    |   ❔  |   ❔  | |
| Pi 1A/1B/CM1/Zero      |   🔥    |   🔥  |   ✅  | Tested on a Pi Zero W |

### Boot methods
The SD card can deliver the kernel, initramfs, APKs, modloop and apkovl. Netboot and rpiboot can only deliver the kernel and initramfs. The rest must be delivered via HTTP or FTP.

When using rpiboot, with a Pi 4, its better to build the boot folder into a boot.img, however this doesn't seem to work on previous models.

| Model        | SD Card | Bootloader via Netboot | Bootloader via rpiboot | Rest via HTTP/FTP | Notes |
|--------------|---------|------------------------|------------------------|-------------------|-------|
| Pi 5         |   ❔    |   ❔                   |   ❔                   |   ❔              | |
| Pi 4/CM4/400 |   ✅    |   ✅                   |   ✅                   |   ✅              | Tested on a Pi 4 (v1.2) 4GB. Tested with onboard ethernet and a USB ethernet adapter. Can be configured either by DHCP or EEPROM option |
| Pi CM4S      |   ❔    |   ❔                   |   ❔                   |   👎              | |
| Pi 3B, 3B+   |   ✅    |   ✅                   |   🚫                   |   ✅              | Tested on a Pi 3B (v1.2).|
| Pi 3A        |   ✅    |   🚫                   |   ❔                   |   👎              | |
| Pi Zero 2    |   ✅    |   🚫                   |   ✅                   |   🔥              | USB ethernet not working. |
| Pi 2B        |   ❔    |   ❔                   |   ❔                   |   ❔              | |
| Pi Zero      |   ✅    |   🚫                   |   ❔                   |   👎              | |
| Pi 1B        |   ✅    |   🚫                   |   🚫                   |   ❔              | |
| Pi 1A, CM1   |   ✅    |   🚫                   |   ❔                   |   👎              | |


### Key
 - `🚫` - Impossible - lacks hardware support.
 - `🔥` - Tested, does not work.
 - `👎` - Untested - likely not working.
 - `❔` - Untested - possibly working.
 - `✅` - Works


# Troubleshooting

## Booting

### Rainbow or black screen
This means the Pi could not load the kernel. Ensure you're using the right architecture for the Pi model you're running. This may also occur when using rpiboot with a raw folder. Package the folder into a FAT32 `boot.img` instead.

### `/dev/root cannot open block device`,  `Kernel panic - not syncing: VFS: Unable to mount root fs on unknown-block(0,0)`
This means the Pi could not load the `boot/initramfs-pi` file. The common reason is due to the SFTP server lacking permissions to read the file.

### `Mounting boot media failed`
This means the Pi could not mount the boot media - for network booting this means that no network connection is possible. Ensure `cmdline.txt` is configured with the correct IP configuration & links to download the rest of the system image. Check `netboot.sh` for the correct `cmdline.txt` configuration.

### `/sbin/init not found in new root`
Your Pi couldn't download the APKs, or the signature is incorrect. Check your HTTP server logs, and make sure the APKs are signed using the correct key.

### Boots, but no customisations are applied
This means the Pi couldn't download the apkovl. Check your HTTP server logs and cmdline.txt.

### Flashing cursor with Raspberry Pi logo(s)
This is normal! The Pi is booting, but the console is not being displayed. This is because the netboot scripts configure the Pi to use the UART console. You can change this to output over HDMI by editing `cmdline.txt` and removing `console=serial0,115200`.