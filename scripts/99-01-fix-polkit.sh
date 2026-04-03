#!/bin/bash

rm -f /etc/polkit-1/localauthority/50-local.d/10-pymc-repeater.pkla || true

# Configure polkit for passwordless service restart
mkdir -p /etc/polkit-1/rules.d/
cat > /etc/polkit-1/rules.d/10-pymc-repeater.rules <<'EOF'
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.systemd1.manage-units" &&
        action.lookup("unit") == "pymc-repeater.service" &&
        subject.user == "repeater") {
        return polkit.Result.YES;
    }
});
EOF