#!/bin/bash

PYMC_SCRIPT_DIR="/tmp/pymc_repeater_install"
PYMC_INSTALL_DIR="/opt/pymc_repeater"
PYMC_CONFIG_DIR="/etc/pymc_repeater"
PYMC_LOG_DIR="/var/log/pymc_repeater"
PYMC_SERVICE_USER="repeater"
PYMC_SERVICE_NAME="pymc-repeater"

echo "# Creating directories..."
mkdir -p "$PYMC_INSTALL_DIR" "$PYMC_CONFIG_DIR" "$PYMC_LOG_DIR" /var/lib/pymc_repeater

echo "# Creating service user..."
useradd --system --home /var/lib/pymc_repeater --shell /sbin/nologin "$PYMC_SERVICE_USER"

echo "# Adding user to hardware groups..."
usermod -a -G gpio "$PYMC_SERVICE_USER" 2>/dev/null || true

echo "# Cleaning old pyMC Repeater installation files..."
# Remove old repeater directory to ensure clean install
rm -rf "$PYMC_INSTALL_DIR" 2>/dev/null || true
rm -rf "$PYMC_SCRIPT_DIR" 2>/dev/null || true
rm -rf "$PYMC_CONFIG_DIR" 2>/dev/null || true

echo "# clone pyMC Repeater"
git clone --single-branch --branch feat/companion https://github.com/rightup/pyMC_Repeater.git $PYMC_SCRIPT_DIR
cd $PYMC_SCRIPT_DIR

echo "# Generating version file..."
cd "$SCRIPT_DIR"
# Generate version file using setuptools_scm before copying
if [ -d .git ]; then
    git fetch --tags 2>/dev/null || true
    # Write the version file that will be copied
    GENERATED_VERSION=$(python3 -m setuptools_scm 2>&1 || echo "unknown (setuptools_scm not available)")
    python3 -c "from setuptools_scm import get_version; get_version(write_to='repeater/_version.py')" 2>&1 || echo "    Warning: Could not generate _version.py file"
    echo "    Generated version: $GENERATED_VERSION"
fi

echo "# Setting up installation files"
cp -r "$PYMC_SCRIPT_DIR/repeater" "$PYMC_INSTALL_DIR/"
cp "$PYMC_SCRIPT_DIR/pyproject.toml" "$PYMC_INSTALL_DIR/"
cp "$PYMC_SCRIPT_DIR/README.md" "$PYMC_INSTALL_DIR/"
cp "$PYMC_SCRIPT_DIR/manage.sh" "$PYMC_INSTALL_DIR/" 2>/dev/null || true
cp "$PYMC_SCRIPT_DIR/pymc-repeater.service" "$PYMC_INSTALL_DIR/" 2>/dev/null || true
cp "$PYMC_SCRIPT_DIR/radio-settings.json" /var/lib/pymc_repeater/ 2>/dev/null || true
cp "$PYMC_SCRIPT_DIR/radio-presets.json" /var/lib/pymc_repeater/ 2>/dev/null || true

echo "# Installing configuration..."
cp "$PYMC_SCRIPT_DIR/config.yaml.example" "$PYMC_CONFIG_DIR/config.yaml.example"
if [ ! -f "$PYMC_CONFIG_DIR/config.yaml" ]; then
    cp "$PYMC_SCRIPT_DIR/config.yaml.example" "$PYMC_CONFIG_DIR/config.yaml"
fi

echo "# Setting permissions..."
chown -R "$PYMC_SERVICE_USER:$PYMC_SERVICE_USER" "$PYMC_INSTALL_DIR" "$PYMC_CONFIG_DIR" "$PYMC_LOG_DIR" /var/lib/pymc_repeater
chmod 750 "$PYMC_CONFIG_DIR" "$PYMC_LOG_DIR" /var/lib/pymc_repeater
# Ensure the service user can create subdirectories in their home directory
chmod 755 /var/lib/pymc_repeater
# Pre-create the .config directory that the service will need
mkdir -p /var/lib/pymc_repeater/.config/pymc_repeater
chown -R "$PYMC_SERVICE_USER:$PYMC_SERVICE_USER" /var/lib/pymc_repeater/.config

echo "# Installing dependencies and pyMC_Repeater"

cd "$PYMC_SCRIPT_DIR"
# Suppress pip root user warnings
export PIP_ROOT_USER_ACTION=ignore
# Calculate version from git for setuptools_scm
if [ -d .git ]; then
    git fetch --tags 2>/dev/null || true
    GIT_VERSION=$(python3 -m setuptools_scm 2>/dev/null || echo "1.0.5")
    export SETUPTOOLS_SCM_PRETEND_VERSION="$GIT_VERSION"
    echo "Installing version: $GIT_VERSION"
else
    export SETUPTOOLS_SCM_PRETEND_VERSION="1.0.5"
fi

python3 -m pip install --force-reinstall --no-cache-dir .

echo "Setting hostname to ultrapeater..."
echo "ultrapeater" > /etc/hostname

echo "# Installing systemd service..."
cp "$PYMC_SCRIPT_DIR/pymc-repeater.service" /etc/systemd/system/
systemctl daemon-reload

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

echo "Enable pyMC_Repeater start on boot"
systemctl enable pymc-repeater
systemctl start pymc-repeater

echo "Clean up install files"
rf -rf $PYMC_SCRIPT_DIR