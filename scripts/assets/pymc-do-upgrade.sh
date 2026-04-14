#!/bin/bash
# pymc-do-upgrade: invoked by the repeater service user via sudo for OTA upgrades.
# Usage: sudo /usr/local/bin/pymc-do-upgrade [channel] [pretend-version]
set -e

PYMC_SCRIPT_DIR="/tmp/pymc_repeater_install"
PYMC_CORE_DIR="/tmp/pymc_core_install"
PYMC_INSTALL_DIR="/opt/pymc_repeater"
PYMC_SERVICE_USER="repeater"
PYMC_SERVICE_NAME="pymc-repeater"
PYMC_REPO_URL="https://github.com/rightup"
CHANNEL="${1:-dev}"

CHANNEL="${1:-main}"
PRETEND_VERSION="${2:-}"
# Validate: only allow safe git ref characters
if ! [[ "$CHANNEL" =~ ^[a-zA-Z0-9._/-]{1,80}$ ]]; then
    echo "Invalid channel name: $CHANNEL" >&2
    exit 1
fi
export PIP_ROOT_USER_ACTION=ignore
# If caller supplied a version string, tell setuptools_scm to use it (sudo
# strips env vars so it is passed as a positional argument instead).

echo "# Clone pyMC Core"
git clone --single-branch --branch $CHANNEL $PYMC_REPO_URL/pyMC_Core.git $PYMC_CORE_DIR
cd $PYMC_CORE_DIR

echo "Prepare pip"
cd "$PYMC_CORE_DIR"
# Suppress pip root user warnings
export PIP_ROOT_USER_ACTION=ignore

echo "# Installing core"
python3 -m pip install --break-system-packages .

echo "# Clone pyMC Repeater"
git clone --single-branch --branch $CHANNEL $PYMC_REPO_URL/pyMC_Repeater.git $PYMC_SCRIPT_DIR
cd $PYMC_SCRIPT_DIR

[ -n "$PRETEND_VERSION" ] && export SETUPTOOLS_SCM_PRETEND_VERSION="$PRETEND_VERSION"

echo "# Setting up installation files"
cp -r "$PYMC_SCRIPT_DIR/repeater" "$PYMC_INSTALL_DIR/"
cp "$PYMC_SCRIPT_DIR/pyproject.toml" "$PYMC_INSTALL_DIR/"
cp "$PYMC_SCRIPT_DIR/README.md" "$PYMC_INSTALL_DIR/"
cp "$PYMC_SCRIPT_DIR/manage.sh" "$PYMC_INSTALL_DIR/" 2>/dev/null || true
cp "$PYMC_SCRIPT_DIR/pymc-repeater.service" "$PYMC_INSTALL_DIR/" 2>/dev/null || true

echo "# Setting permissions..."
chown -R "$PYMC_SERVICE_USER:$PYMC_SERVICE_USER" "$PYMC_INSTALL_DIR"

python3 -m pip install --break-system-packages .

echo "Clean up install files"
rm -rf $PYMC_SCRIPT_DIR
rm -rf $PYMC_CORE_DIR

echo "Done, restart service"