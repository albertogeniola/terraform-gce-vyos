#!/bin/bash

# Configure
./configure --architecture amd64 --build-by "Github Actions" --build-type=release --version equuleus

# Build
sudo make $1


