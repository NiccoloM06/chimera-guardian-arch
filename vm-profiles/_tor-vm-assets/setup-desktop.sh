#!/bin/bash

# =======================================================================================
#  DESKTOP SETUP SCRIPT | CHIMERA GUARDIAN ARCH - TOR VM
#  To be executed as root upon first login to the Tor VM.
# =======================================================================================

echo "### 🚀 Starting desktop environment and secure browser setup... ###"

# --- Privilege Check ---
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ This script must be run as root." >&2
    exit 1
fi

# --- Stage 1: System Update & Desktop Installation ---
echo "🔧 Updating the system and installing the LXDE desktop environment..."
# Ensure non-free is enabled for firmware/keyring if needed later
sed -i 's/main/main contrib non-free non-free-firmware/g' /etc/apt/sources.list
apt-get update && apt-get upgrade -y
# lxde-core is a minimal desktop, lightdm is the display manager
apt-get install -y lxde-core lightdm --no-install-recommends

# --- Stage 2: Browser Installation ---
echo "🌐 Installing Tor Browser and Firefox ESR..."
# torbrowser-launcher handles the download and updates of Tor Browser
# firefox-esr is the Extended Support Release, generally more stable.
apt-get install -y torbrowser-launcher firefox-esr --no-install-recommends

# --- Stage 3: Pre-configuring Firefox for I2P ---
echo "🔒 Configuring Firefox for I2P usage..."
# This method uses Firefox policies to lock the settings, which is the most robust approach.
FIREFOX_POLICY_DIR="/etc/firefox-esr/policies"
mkdir -p "$FIREFOX_POLICY_DIR"
cat <<'EOF' > "${FIREFOX_POLICY_DIR}/policies.json"
{
  "policies": {
    "Proxy": {
      "Mode": "manual",
      "HTTPProxy": "127.0.0.1:4444",
      "UseHTTPProxyForAllProtocols": true,
      "Locked": true
    },
    "Homepage": {
        "URL": "http://127.0.0.1:7657/",
        "Locked": true
    },
    "DisableAppUpdate": true
  }
}
EOF

# --- Stage 4: Create a Standard User ---
echo "👤 Creating a standard user for desktop use."
read -p "Enter a name for the new user (e.g., 'anonymous'): " NEW_USER
if [ -z "$NEW_USER" ]; then
    echo "Invalid username. Aborting."
    exit 1
fi
adduser "$NEW_USER"

# --- Finalization ---
echo ""
echo "🎉 Setup complete!"
echo "The system will reboot in 5 seconds."
echo "After rebooting, log in with the user '${NEW_USER}' and the password you just created."
sleep 5
reboot