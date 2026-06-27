#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    show_error "Installation requires root privileges.\n\nPlease run: sudo $0"
    exit 1
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

OPENHOP_SCRIPT_DIR="/tmp/openhop_repeater_install"
OPENHOP_REPO_URL="${1:-https://github.com/openhop-dev/openhop_repeater.git}"
OPENHOP_REPO_BRANCH="${2:-dev}"

git clone --single-branch --branch $OPENHOP_REPO_BRANCH $OPENHOP_REPO_URL $OPENHOP_SCRIPT_DIR

echo "# Copy in our BoardConfig so that you only get the options of our two variants"
cp $SCRIPT_DIR/assets/ultrapeater-radio-settings.json $OPENHOP_SCRIPT_DIR/radio-settings.json

echo "# Enable GPIOd to prevent errors on first start"
sed -i "/^  cs_pin:.*/a\\  gpio_chip: 1" "$OPENHOP_SCRIPT_DIR/config.yaml.example"
sed -i "/^  gpio_chip:.*/a\\  use_gpiod_backend: true" "$OPENHOP_SCRIPT_DIR/config.yaml.example"

cd $OPENHOP_SCRIPT_DIR
./manage.sh install

rm -rf $OPENHOP_SCRIPT_DIR
sudo systemctl enable --now openhop-repeater.service