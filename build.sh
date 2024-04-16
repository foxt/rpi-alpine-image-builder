set -e
export ALPINE_VERSION=3.19
export APPDIR=$(dirname "$0")

docker run --rm \
    -v $APPDIR:/app \
    -v $APPDIR/workdir:/workdir \
    -e ALPINE_VERSION \
    -w /app \
    --tty -i \
    alpine:$ALPINE_VERSION \
    "sh" -c 'apk add bash; /app/scripts/build.sh'