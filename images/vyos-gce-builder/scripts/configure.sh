#!/bin/bash
# Setup login_helper
chmod +x /opt/login_helper/login_helper.sh
sudo mv /home/vyos/login_helper.service /etc/systemd/system/login_helper.service

# Setup conf_reloader
chmod +x /opt/conf_reloader/conf_reloader.sh
chmod +x /opt/conf_reloader/command_helper.sh
sudo mv /home/vyos/conf_reloader.service /etc/systemd/system/conf_reloader.service
sudo python3 -m venv /opt/conf_reloader/.venv
sudo /opt/conf_reloader/.venv/bin/pip3 install -r /opt/conf_reloader/requirements.txt

# Install services
sudo systemctl daemon-reload
sudo systemctl enable login_helper.service
sudo systemctl enable conf_reloader.service

# Configure motd
sudo mv /home/vyos/motd /etc/motd