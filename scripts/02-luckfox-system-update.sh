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
groupadd gpio
usermod -aG gpio pico
chgrp gpio /dev/gpiochip*
chmod 660 /dev/gpiochip*
chgrp gpio /dev/spidev*
chmod 660 /dev/spidev*

echo "Adding chgrp to rc.local - hacky but it works"
echo "chgrp gpio /dev/gpiochip*" >> /etc/rc.local
echo "chmod 660 /dev/gpiochip*" >> /etc/rc.local
echo "chgrp gpio /dev/spidev*" >> /etc/rc.local
echo "chmod 660 /dev/spidev*" >> /etc/rc.local

echo "Disabling the UARTS we need for GPIO and enabling SPI"
luckfox-config uart_disable 4 1
luckfox-config uart_disable 2 1
luckfox-config spi_enable

reboot