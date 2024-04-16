# Raspberry Pi Alpine Image Builder

This is a rudimentary script to build a custom Alpine Linux image for the Raspberry Pi. The goals of this project are:
  - Build a custom ramdisk based OSimage for the Raspberry Pi 3/4/Zero2.
    - It would be a nice to have to support the Pi1/2/Zero. Shouldn't be too hard to implement as there's nothing in these scripts that has a hard dependency on the architecture, but I'm focused on ARM64 for now.
    - And, I don't have a Pi 5 to test. Should™ work the same way as a Pi 4
  - Entirely built on a workstation - i.e. not: put a fresh SD card in the Pi to modify an existing image
  - Built in a 'clean-room' fashion - booting an Alpine image and immediately running `lbu commit` shows that changes are made to the system during the boot process, and can be based on unique configuration (for example, /etc/resolv.conf is filled in with the DNS server & hostname from DHCP).
  - Netboot and or rpiboot for ease of development.
   

## Process
As Alpine must be built on Alpine, an ephemeral Docker container is used to run the build scripts. The scripts clones the [aports](https://gitlab.alpinelinux.org/alpine/aports) repo and uses custom `mkimg` and `genapkovl` profiles to generate a `tar.gz` folder which can be extracted to the root of a FAT32 SD card and inserted into the Pi.

Booting from the network or via [rpiboot](https://github.com/raspberrypi/usbboot) is possible, however is a little bit more involved, as:

    - Neither netboot or rpiboot can only deliver the Linux kernel and initramfs, for the APKs, modloop & apkovl, these must be delivered via HTTP or FTP.
      - This also means that both netboot and rpiboot require the Raspberry Pi to be connected via an Ethernet connection, thus, meaning this cannot be performed on the Zero or the Pi 3A.
      - It may be possible to include `wpa_supplicant` into the initramfs to allow rpiboot on boards lacking Ethernet, however this is currently out of scope.
    - Netboot requires a SFTP server to deliver the files.
    - On Pi 4 and 5, the SFTP server IP address can be [configured in the EEPROM](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#TFTP_IP). On the Pi3, this must be handed out by the DHCP server.
    - rpiboot is extremely unreliable when booting from a raw folder, thus, you should package the folder into a FAT32 `boot.img`, and use a `config.txt` with `boot_ramdisk=1`.
    - A script is provided for macOS users to allow network booting using the built in tftp server.

## Tested Configurations

| Model              | via SD Card | via Netboot | via rpiboot | Notes       |
|--------------------|-------------|-------------|-------------|-------------|
| Pi 1B,             | unsupported | N/A         | N/A         | `armhf` not currently supported (but should be easy to add) |
| Pi 1A, CM1, Zero   | unsupported | N/A         |             | `armhf` not currently supported (but should be easy to add) |
| Pi 2B (1.1)        | unsupported | N/A         | N/A         | `armv7` not currently supported (but should be easy to add) |
| Pi 2B (1.2)        | unsupported |             | N/A         | `armv7` not currently supported (but should be easy to add) |
| Pi 3B, 3B+         | untested    | untested    | N/A         | Should work. Haven't tried it yet. |
| CM3                | untested    | untested    | untested    | Should work. Haven't tried it yet. |
| Pi 3A, Zero 2,     | untested    | N/A         | unsupported | Should work. Haven't tried it yet. |
| Pi 4               | untested    | works       | works       | |
| Pi 400, CM4, Pi 5  | untested    | untested    | untested    | Should work. Haven't tried it yet. |


# Troubleshooting

## Booting

### Rainbow or black screen
This means the Pi could not load the kernel. Make sure the kernel is in the right place, and that the Pi can access the files. This may also occur when using rpiboot with a raw folder. Package the folder into a FAT32 `boot.img` instead.

### `/dev/root cannot open block device`,  `Kernel panic - not syncing: VFS: Unable to mount root fs on unknown-block(0,0)`
This means the Pi could not load the `boot/initramfs-pi` file. Check that the file is in the right place, and that the Pi can access the files. This can happen if your SFTP permissions are incorrect.

### `Couldn't mount boot media` and going into a recovery shell when using net/rpiboot
This means your `cmdline.txt` is not configured to loaad the rest of the system from HTTP. Check `netboot.sh` for the correct `cmdline.txt` configuration.

### `/sbin/init not found in new root`
Your Pi couldn't download the APKs, or the signature is incorrect. Check your HTTP server logs, and make sure the APKs are signed using the correct key.

### Boots, but no customisations are applied
This means the Pi couldn't download the apkovl. Check your HTTP server logs and cmdline.txt.

### Flashing cursor with Raspberry Pi logo(s)
This is normal! The Pi is booting, but the console is not being displayed. This is because the netboot scripts configure the Pi to use the UART console. You can change this to output over HDMI by editing `cmdline.txt` and removing `console=serial0,115200`.