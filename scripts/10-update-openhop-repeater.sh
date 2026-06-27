#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    show_error "Installation requires root privileges.\n\nPlease run: sudo $0"
    exit 1
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

OPENHOP_SCRIPT_DIR="/tmp/openhop_repeater_install"
OPENHOP_REPO_URL="${1:-https://github.com/openhop-dev/openhop-repeater.git}"
OPENHOP_REPO_BRANCH="${2:-dev}"

git clone --single-branch --branch $OPENHOP_REPO_BRANCH $OPENHOP_REPO_URL $OPENHOP_SCRIPT_DIR

cd $OPENHOP_SCRIPT_DIR
./manage.sh upgrade

rm -rf $OPENHOP_SCRIPT_DIR
sudo systemctl enable --now openhop-repeater.service