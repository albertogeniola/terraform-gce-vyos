#!/bin/bash

# Allocate the folder for init-shell script & conf_reloader
sudo mkdir -p /opt/login_helper
sudo chown -vR vyos /opt/login_helper
sudo mkdir -p /var/run/login_helper
sudo chown -vR vyos /var/run/login_helper
sudo mkdir -p /opt/conf_reloader
sudo chown -vR vyos /opt/conf_reloader
sudo mkdir -p /var/run/conf_reloader
sudo chown -vR vyos /var/run/conf_reloader

# Install the Google Ops Agent
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
DIST=$DEBIAN_VERSION_NAME
sudo tee /etc/apt/sources.list.d/google-cloud.list << EOM
deb http://packages.cloud.google.com/apt google-compute-engine-${DIST}-stable main
deb http://packages.cloud.google.com/apt google-cloud-packages-archive-keyring-${DIST} main
EOM

# TODO: REMOVE THE FOLLOWING LINES AND ANTICIPATE THIS curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
# Setup the official repositories
sudo tee /etc/apt/sources.list.d/debian-${DIST}.list << EOM
deb http://deb.debian.org/debian/ bullseye main
deb-src http://deb.debian.org/debian/ bullseye main
deb http://security.debian.org/debian-security bullseye-security main
deb-src http://security.debian.org/debian-security bullseye-security main
deb http://deb.debian.org/debian/ bullseye-updates main
deb-src http://deb.debian.org/debian bullseye-updates main
EOM

echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install apt-transport-https ca-certificates gnupg
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

# Install compute agent & cloud-sdk
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt install -y google-cloud-packages-archive-keyring
sudo DEBIAN_FRONTEND=noninteractive apt install -y google-compute-engine google-osconfig-agent google-cloud-sdk

# Install OPS agent
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install --uninstall-standalone-logging-agent --uninstall-standalone-monitoring-agent

# Move the configuration file into target directory
sudo mv /home/vyos/config.yaml /etc/google-cloud-ops-agent/config.yaml

# Install python3 pip, we'll need this later for the installation of requirements
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y python3-pip python3-venv

# Reboot
sudo reboot