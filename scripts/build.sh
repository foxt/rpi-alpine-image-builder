#!/bin/bash
set -e
trap "echo script failed; bash -i" ERR
ALPINE_VERSION=${ALPINE_VERSION}
APP_DIR=/app
WORKDIR=/workdir


# Install dependencies
apk update
apk add alpine-sdk alpine-conf squashfs-tools 

# Clone the aports repository
if [ ! -d $WORKDIR/aports/.git ]; then
    if [ -d $WORKDIR/aports/ ]; then
        rm -rf $WORKDIR/aports/
    fi
    git clone -b $ALPINE_VERSION-stable --depth=1 https://gitlab.alpinelinux.org/alpine/aports.git /$WORKDIR/aports
else
    cd $WORKDIR/aports
    git checkout $ALPINE_VERSION-stable
    git reset --hard
    git clean -f
    git pull
    cd $APP_DIR
fi

# Copy the package to the aports repository
cp -fvr $APP_DIR/alpine/aports/* $WORKDIR/aports/

# Generate signing keys
if [ ! -f $APP_DIR/keys/build.rsa ]; then
    mkdir -p $APP_DIR/keys
    abuild-keygen -a -n
    mv /root/.abuild/*.rsa.pub $APP_DIR/keys/build.rsa.pub
    mv /root/.abuild/*.rsa $APP_DIR/keys/build.rsa  
fi
cp $APP_DIR/keys/build.rsa.pub /etc/apk/keys/
mkdir -p /root/.abuild
echo "PACKAGER_PRIVKEY=\"$APP_DIR/keys/build.rsa\"" >> /root/.abuild/abuild.conf

rm -rf $WORKDIR/output
sh $WORKDIR/aports/scripts/mkimage.sh \
    --tag $ALPINE_VERSION-rpicustom \
    --outdir $WORKDIR/output \
    --profile rpicustom \
    --arch aarch64 \
    --hostkeys \
    --repository http://dl-cdn.alpinelinux.org/alpine/v$ALPINE_VERSION/main
