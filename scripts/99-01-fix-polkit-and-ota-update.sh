#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    show_error "Installation requires root privileges.\n\nPlease run: sudo $0"
    exit 1
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "# Configuring sudoers for service management..."
mkdir -p /etc/sudoers.d
cat > /etc/sudoers.d/pymc-repeater <<'EOF'
# Allow repeater user to manage the pymc-repeater service without password
repeater ALL=(root) NOPASSWD: /usr/bin/systemctl restart pymc-repeater, /usr/bin/systemctl stop pymc-repeater, /usr/bin/systemctl start pymc-repeater, /usr/bin/systemctl status pymc-repeater, /usr/local/bin/pymc-do-upgrade
EOF
chmod 0440 /etc/sudoers.d/pymc-repeater

# Configure polkit for passwordless service restart
mkdir -p /etc/polkit-1/localauthority/50-local.d
cat > /etc/polkit-1/localauthority/50-local.d/10-pymc-repeater.pkla <<'EOF'
[Allow repeater to restart pymc-repeater service]
Identity=unix-user:repeater
Action=org.freedesktop.systemd1.manage-units
ResultAny=yes
ResultInactive=yes
ResultActive=yes
EOF
chmod 0644 /etc/polkit-1/localauthority/50-local.d/10-pymc-repeater.pkla

echo "# Copy in our custom OTA update script"
cp $SCRIPT_DIR/assets/pymc-do-upgrade /usr/local/bin/pymc-do-upgrade
chmod +x /usr/local/bin/pymc-do-upgrade

