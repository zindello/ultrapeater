#!/bin/bash

echo "Setting localtime to UTC..."
rm /etc/localtime
ln -sf /usr/share/zoneinfo/UTC /etc/localtime

DEBIAN_FRONTEND=noninteractive

echo "Updating apt sources"
apt update

echo "Installing packages"
apt install -y --option Dpkg::Options::="--force-confold" locales git libyaml-cpp-dev libbluetooth-dev openssl libssl-dev libulfius-dev fonts-noto-color-emoji ninja-build chrony software-properties-common python-is-python3 python3.10-venv lsof spi-tools vim mtd-utils jq rsync libffi-dev jq python3-pip python3-rrdtool python3.10-venv wget swig build-essential python3-dev
if [[ $? -eq 2 ]]; then echo "Error, step failed..."; fi

echo "Upgrade pip to latest available version"
python3 -m pip install --upgrade pip
python3 -m pip install setuptools_scm yq

echo "Adding GPIO user and fixing gpiochip permissions"
sudo groupadd gpio
sudo usermod -aG gpio pico
sudo chgrp gpio /dev/gpiochip*
sudo chmod 660 /dev/gpiochip*

cat <<EOF >/etc/luckfox.cfg
RGB_ENABLE=0
SPI0_M0_STATUS=1
SPI0_M0_MISO_ENABLE=1
SPI0_M0_SPEED=1000000
SPI0_M0_CS_ENABLE=0
SPI0_M0_MODE=1
UART2_M1_STATUS=0
UART4_M0_STATUS=0
I2C4_M1_STATUS=0
I2C4_M1_SPEED=0
EOF

reboot