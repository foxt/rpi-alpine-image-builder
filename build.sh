set -e

# Set the version of Alpine Linux to use.
export ALPINE_VERSION=3.19

# Set the architecture to build for.
#  - armhf: Raspberry Pi 1, Zero, CM1
#  - armv7: Raspberry Pi 2, 3, CM3, Zero 2
#  - aarch64: Raspberry Pi 3, 4, 5, CM3, CM4, Zero 2
export BUILD_ARCH=aarch64

# Directories: (w - created by script, r - from repository)
#  - $APPDIR/scripts (r) - Contains the scripts used to build the image.
#  - $APPDIR/alpine (r) - Stores the files to be 'overlaid' on the aports repository. Stores the configuration files used to build the image.
#  - $APPDIR/keys (w) - Stores the signing keys used to sign the packages. This should be kept secret, but saved to allow for updates.
#  - $WORKDIR/aports (w) - A clone of the aports repository.
#  - $WORKDIR/output (w) - The output directory for the image.
export APPDIR=$(dirname "$0")
export WORKDIR=$APPDIR/workdir


mkdir -p $WORKDIR

docker run --rm \
    -v $APPDIR:/app \
    -v $WORKDIR:/workdir \
    -e ALPINE_VERSION \
    -e BUILD_ARCH \
    -w /app \
    --tty -i \
    alpine:$ALPINE_VERSION \
    "sh" -c 'apk add bash; /app/scripts/build.sh'