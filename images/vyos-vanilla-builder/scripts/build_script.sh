#!/bin/bash
git clone -b "$VYOS_VERSION" --single-branch https://github.com/vyos/vyos-build
cd vyos-build
./configure --architecture amd64 --build-by "$BUILD_BY"
#sudo make iso
sudo make GCE
