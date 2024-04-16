set -e
export ALPINE_VERSION=3.19

docker run --rm \
    -v $(pwd):/app \
    -e ALPINE_VERSION \
    -w /app \
    -i \
    alpine:$ALPINE_VERSION \
    "sh" -c 'apk add bash; /app/scripts/build.sh'