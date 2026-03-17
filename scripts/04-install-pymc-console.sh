#!/bin/bash

PYMC_C_TMP_FILE="/tmp/pymc-ui.tar.gz"
PYMC_C_CONSOLE_DIR="/opt/pymc_console"
PYMC_C_UI_DIR="$PYMC_C_CONSOLE_DIR/web/html"
PYMC_C_UI_REPO="dmduran12/pymc_console-dist"
PYMC_C_UI_RELEASE_URL="https://github.com/${PYMC_C_UI_REPO}/releases"

rm -rf $PYMC_C_CONSOLE_DIR

echo "# Downloading dashboard..."
curl -fsSL -o "$PYMC_C_TMP_FILE" "${PYMC_C_UI_RELEASE_URL}/latest/download/pymc-ui-latest.tar.gz"

echo "# Rollin out dashboard..."
mkdir -p "$PYMC_C_UI_DIR"
tar -xzf "$PYMC_C_TMP_FILE" -C "$PYMC_C_UI_DIR"
chown -R repeater:repeater "$PYMC_C_CONSOLE_DIR" 2>/dev/null || true

rm -rf $PYMC_C_TMP_FILE

systemctl restart pymc-repeater