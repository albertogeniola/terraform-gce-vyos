#!/bin/bash
# Run the iso_builder script inside the build container (non-interactively)
docker run \
    --rm \
    -v "$(pwd)":/vyos \
    -v "/$HOME/build_scripts":/home/vyos_bld/build_scripts \
    -e VYOS_VERSION="$VYOS_VERSION" \
    -e BUILD_BY="$BUILD_BY" \
    -w /vyos \
    --privileged \
    --sysctl net.ipv6.conf.lo.disable_ipv6=0 \
    -e GOSU_UID=$(id -u) \
    -e GOSU_GID=$(id -g) \
    "vyos/vyos-build:$VYOS_VERSION" \
    bash "/home/vyos_bld/build_scripts/build_script.sh"
