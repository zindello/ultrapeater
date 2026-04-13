#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    show_error "Installation requires root privileges.\n\nPlease run: sudo $0"
    exit 1
fi

echo "### ULTRAPEATER WIFI SETUP SCRIPT ###"

echo "Installing Packages"
apt install -y wpasupplicant

echo "Configure the networkd DHCP client for Wifi"
networkfile="/etc/systemd/network/20-wireless.network"
cat << EOF > $networkfile
[Match]
Name=wlan0
[Link]
RequiredForOnline=routable
[Network]
DHCP=yes
IgnoreCarrierLoss=3s
[DHCPv4]
RouteMetric=100
EOF

systemctl restart systemd-networkd

wifi_bt_init

sleep 2
echo "Scanning for networks"
wpa_cli -i wlan0 scan
sleep 5
wpa_cli -i wlan0 scan_results

read -p "Enter your wifi network name (Case Sensitive): " network
read -s -p "Enter your wifi network passphrase: " passphrase
wpa_passphrase $network $passphrase > /etc/wpa_supplicant.conf
echo ""

killall wpa_supplicant

wifi_bt_init

networkctl reconfigure wlan0