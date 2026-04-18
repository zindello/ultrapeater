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

cd $PYMC_SCRIPT_DIR
./manage.sh upgrade

rm -rf $PYMC_SCRIPT_DIR