#!/bin/bash

echo "Injecting the ability to manually enable/disable the things we need to in the luckfox-config script"
sudo sed -i '/elif \[ -z "\$1" \]; then/i \
elif [ "$1" == "rgb_disable" ]; then\
    luckfox_config_init\
    LF_GUI_ENABLE=0\
    luckfox_rgb_app 0\
elif [ "$1" == "spi_enable" ]; then\
    luckfox_config_init\
    LF_GUI_ENABLE=0\
    luckfox_i2c_app 0 4 1\
    luckfox_spi_app 1 0 0 1 1 1000000\
    echo "SPI Enabled - Reboot for changes to take effect"\
elif [ "$1" == "uart_disable" ]; then\
    luckfox_uart_app 0 $2 $3\
' /usr/bin/luckfox-config

echo "Disabling RGB"
luckfox-config rgb_disable

echo "Increase the size of the tmpfs"
mount -o remount,size=32M /run
echo "tmpfs /run tmpfs rw,nodev,nosuid,size=32M 0 0" | tee -a /etc/fstab

echo "Regenerating SSH keys"
rm /etc/ssh/ssh_host_*
ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""
ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ""
chmod 600 /etc/ssh/ssh_host_*_key
chmod 644 /etc/ssh/ssh_host_*_key.pub
chown root:root /etc/ssh/ssh_host_*
systemctl restart ssh

echo "Disable all the services that we're not going to need"
systemctl disable apt-daily.timer
systemctl disable apt-daily-upgrade.timer
systemctl mask apt-daily.service # try prevent daily updates
systemctl mask apt-daily-upgrade.service # try prevent daily updates
systemctl disable unattended-upgrades
systemctl disable smbd nmbd # samba services, can be enabled via menu
systemctl disable vsftpd.service
systemctl disable ModemManager.service
systemctl disable getty@tty1.service
systemctl disable acpid
systemctl disable acpid.socket
systemctl disable acpid.service
systemctl mask alsa-restore.service
systemctl disable alsa-restore.service
systemctl disable alsa-state.service
systemctl mask sound.target
systemctl disable sound.target
systemctl disable veritysetup.target
systemctl disable systemd-pstore.service

echo "Prepare the switch to networkd"
networkfile="/etc/systemd/network/10-wired.network"
mac="$(awk '/Serial/ {print $3}' /proc/cpuinfo | tail -c 11 | sed 's/^\(.*\)/a2\1/' | sed 's/\(..\)/\1:/g;s/:$//')"
cat << EOF > $networkfile
[Match]
Name=eth0
[Link]
MACAddress=$mac
[Network]
DHCP=yes
EOF

systemctl disable NetworkManager
systemctl disable NetworkManager-dispatcher
systemctl disable NetworkManager-wait-online
systemctl enable systemd-networkd

echo ""
echo "### SYSTEM CONFIG COMPLETE ###"
echo "#### NOTE IP AND SSH IDENTITY WILL CHANGE ON RESTART ####"

reboot