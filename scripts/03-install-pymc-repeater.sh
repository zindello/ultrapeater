#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    show_error "Installation requires root privileges.\n\nPlease run: sudo $0"
    exit 1
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PYMC_SCRIPT_DIR="/tmp/pymc_repeater_install"
PYMC_REPO_URL="${1:-https://github.com/rightup/pyMC_Repeater.git}"
PYMC_REPO_BRANCH="${2:-dev}"

git clone --single-branch --branch $PYMC_REPO_BRANCH $PYMC_REPO_URL $PYMC_SCRIPT_DIR

echo "# Copy in our BoardConfig so that you only get the options of our two variants"
cp $SCRIPT_DIR/assets/ultrapeater-radio-settings.json $PYMC_SCRIPT_DIR/radio-settings.json

echo "# Enable GPIOd to prevent errors on first start"
sed -i "/^  cs_pin:.*/a\\  gpio_chip: 1" "$PYMC_SCRIPT_DIR/config.yaml.example"
sed -i "/^  gpio_chip:.*/a\\  use_gpiod_backend: true" "$PYMC_SCRIPT_DIR/config.yaml.example"

cd $PYMC_SCRIPT_DIR
./manage.sh install

rm -rf $PYMC_SCRIPT_DIR