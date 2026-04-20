#!/bin/bash -e

# Syncloud update agent
# Checks for new RAUC bundles and installs them

# Allow override (used by CI to point at a mock update server).
[ -f /etc/default/syncloud-update ] && . /etc/default/syncloud-update

UPDATE_URL="${UPDATE_URL:-https://updates.syncloud.org}"

# rauc emits proper shell-quoted assignments
# (RAUC_SYSTEM_COMPATIBLE='syncloud-amd64-uefi'); eval to unquote correctly.
eval "$(rauc status --output-format=shell)"
COMPATIBLE="$RAUC_SYSTEM_COMPATIBLE"
CURRENT_VERSION="$RAUC_SLOT_STATUS_BUNDLE_VERSION"

echo "Device: $COMPATIBLE"
echo "Current version: $CURRENT_VERSION"

# Check for update. Server layout:
#   $UPDATE_URL/os/<compatible>/latest.json
#   $UPDATE_URL/os/<compatible>/<bundle>.raucb
# The /os/ namespace reserves room for apps updates under /apps/ later.
MANIFEST=$(curl -sf "$UPDATE_URL/os/$COMPATIBLE/latest.json") || {
    echo "No update available or server unreachable"
    exit 0
}

LATEST_VERSION=$(echo "$MANIFEST" | python3 -c "import json,sys; print(json.load(sys.stdin)['version'])")
BUNDLE_URL=$(echo "$MANIFEST" | python3 -c "import json,sys; print(json.load(sys.stdin)['url'])")

if [[ "$CURRENT_VERSION" == "$LATEST_VERSION" ]]; then
    echo "Already up to date"
    exit 0
fi

echo "Updating from $CURRENT_VERSION to $LATEST_VERSION"

# Download and install
BUNDLE_FILE="/tmp/update.raucb"
curl -f -o "$BUNDLE_FILE" "$BUNDLE_URL"

rauc install "$BUNDLE_FILE"

rm -f "$BUNDLE_FILE"

echo "Update installed, rebooting..."
systemctl reboot
