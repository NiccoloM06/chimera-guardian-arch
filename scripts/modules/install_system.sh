#!/usr/bin/env bash
set -euo pipefail

# =======================================================================================
#  MAIN SYSTEM INSTALLATION MODULE | CHIMERA GUARDIAN ARCH
#  Installs all packages and performs base system configuration.
#  Called by 'make install'.
# =======================================================================================

# --- Source the shared library ---
# shellcheck source=../lib.sh
source "$(dirname "$0")/../lib.sh"

# --- Verify correct execution context ---
if [ "$(id -u)" -ne 0 ]; then
    log "ERROR" "This script must be run as root or with sudo."
    exit 1
fi
if [ -z "${CHIMERA_USER:-}" ]; then
    log "ERROR" "CHIMERA_USER variable not set. Ensure .env is configured."
    exit 1
fi
HOME_DIR=$(getent passwd "$CHIMERA_USER" | cut -d: -f6)
if [ -z "$HOME_DIR" ]; then
    log "ERROR" "Could not determine home directory for user '$CHIMERA_USER'."
    exit 1
fi

log "INFO" "Starting main system installation for user: $CHIMERA_USER"
log "INFO" "Full installation log is being written to: $LOG_FILE"

# --- Pre-Install Dependency Checks ---
log "INFO" "Checking essential dependencies..."
check_dep "pacman"
check_dep "git"
check_dep "curl"
check_dep "sudo"
check_dep "bash"
log "SUCCESS" "Essential dependencies met."

#--------------------------------------------------------------------------------
# STAGE 0: DRIVER SELECTION (INTERACTIVE)
#--------------------------------------------------------------------------------
log "INFO" "--- STAGE 0: HARDWARE DRIVER SELECTION ---"
pacman -Syu --noconfirm
pacman -S --noconfirm linux-firmware sof-firmware # Base firmware

# Wi-Fi / Bluetooth
read -r -p "Install common Wi-Fi (Broadcom) and Bluetooth drivers? (y/N) " install_wifi
if [[ "$install_wifi" =~ ^([yY])$ ]]; then
    pacman -S --noconfirm broadcom-wl-dkms bluez bluez-utils || log "WARN" "Could not install Wi-Fi/Bluetooth drivers."
fi

# Graphics Drivers (Allow Multiple Selections)
log "INFO" "Selecting graphics drivers (you can choose multiple if needed, e.g., for hybrid graphics):"
GFX_DRIVERS="mesa" # Mesa is always needed as a base

read -r -p "Install Intel drivers (mesa)? [Y/n] " install_intel
# Mesa is already included, so no action needed, just confirmation log
if [[ ! "$install_intel" =~ ^([nN])$ ]]; then log "INFO" "Intel drivers (mesa) selected."; fi

read -r -p "Install AMD drivers (mesa + xf86-video-amdgpu)? (y/N) " install_amd
if [[ "$install_amd" =~ ^([yY])$ ]]; then
    GFX_DRIVERS+=" xf86-video-amdgpu"
    log "INFO" "AMD drivers selected."
fi

read -r -p "Install NVIDIA proprietary drivers (nvidia-dkms)? (y/N) " install_nvidia
if [[ "$install_nvidia" =~ ^([yY])$ ]]; then
    GFX_DRIVERS+=" nvidia-dkms"
    log "INFO" "NVIDIA drivers selected."
fi

pacman -S --noconfirm "$GFX_DRIVERS"
log "SUCCESS" "Graphics drivers installation configured."
sleep 2

#--------------------------------------------------------------------------------
# STAGE 1: CORE SECURITY COMPONENTS
#--------------------------------------------------------------------------------
log "INFO" "--- STAGE 1: INSTALLING CORE SECURITY COMPONENTS ---"
pacman -S --noconfirm linux-hardened linux-hardened-headers ufw dnscrypt-proxy i2p

log "INFO" "Configuring Encrypted DNS (DNSCrypt)..."
systemctl enable dnscrypt-proxy.service
chattr -i /etc/resolv.conf 2>/dev/null || true
echo "nameserver 127.0.0.1" > /etc/resolv.conf
chattr +i /etc/resolv.conf

log "INFO" "Configuring Firewall (UFW)..."
systemctl enable ufw.service
ufw --force enable
ufw default deny incoming
ufw default allow outgoing

log "INFO" "Enabling I2P Service..."
systemctl enable i2p.service
log "SUCCESS" "Core security components installed and configured."

#--------------------------------------------------------------------------------
# STAGE 2: AUR SETUP & BLACKARCH REPOSITORY
#--------------------------------------------------------------------------------
log "INFO" "--- STAGE 2: CONFIGURING AUR AND BLACKARCH ---"
pacman -S --noconfirm base-devel

log "INFO" "Installing AUR Helper (paru)..."
# Run paru installation as the target user
sudo -u "$CHIMERA_USER" bash -c 'cd /tmp && git clone --depth=1 https://aur.archlinux.org/paru.git && cd paru && makepkg -si --noconfirm'

log "INFO" "Adding BlackArch repository..."
cd /tmp && curl -sO https://blackarch.org/strap.sh
# Checksum verification (replace with actual check)
# if ! sha1sum -c <<< "CHECKSUM strap.sh"; then ... fi
chmod +x strap.sh && ./strap.sh
pacman -Syu --noconfirm
log "SUCCESS" "AUR helper (paru) and BlackArch repositories are ready."

#--------------------------------------------------------------------------------
# STAGE 2.5: OPTIONAL EXTERNAL WIFI DRIVERS (AUR)
#--------------------------------------------------------------------------------
log "INFO" "--- STAGE 2.5: OPTIONAL EXTERNAL WI-FI DRIVERS ---"
read -r -p "Do you want to attempt installation of common drivers for EXTERNAL USB Wi-Fi adapters (e.g., Alfa, TP-Link, Panda)? (Requires AUR access) (y/N) " install_external_wifi
if [[ "$install_external_wifi" =~ ^([yY])$ ]]; then
    log "INFO" "Attempting to install common external Wi-Fi drivers from AUR..."
    # Expanded list including common Realtek, Ralink, and Atheros USB chipsets
    EXTERNAL_WIFI_PACKAGES=(
        # --- Realtek ---
        "rtl88xxau-aircrack-dkms-git"  # Very common Alfa chipset (AC support)
        "rtl8812au-dkms-git"         # Common Dual-band AC adapters
        "rtl8188eus-dkms"            # Common TP-Link/Generic N adapters
        "r8168-dkms"                 # Some Realtek Ethernet/WiFi combos (less common for USB)

        # --- Ralink / MediaTek ---
        "rt3070-dkms"                # Common chipset in older Alfa N adapters / Panda PAU05
        "mt7610u_wifi_sta_dkms"      # MediaTek AC600 USB adapters
        "mt7612u_wifi_sta_dkms"      # MediaTek AC1200 USB adapters

        # --- Atheros ---
        # Most Atheros USB drivers are in-kernel via ath9k_htc, but adding a common one just in case
        "carl9170-dkms"              # Less common, but used in some high-power adapters
    )
    # Install the packages as the user using paru
    sudo -u "$CHIMERA_USER" --preserve-env=CHIMERA_ROOT bash -c "paru -S --noconfirm --needed ${EXTERNAL_WIFI_PACKAGES[*]}" || log "WARN" "Some external Wi-Fi drivers may have failed to install. Check paru output in the log."
    log "SUCCESS" "Attempted installation of external Wi-Fi drivers."
else
    log "INFO" "Skipping installation of optional external Wi-Fi drivers."
fi
sleep 2

#--------------------------------------------------------------------------------
# STAGE 3: PROFESSIONAL SOFTWARE SUITE (AUR)
#--------------------------------------------------------------------------------
log "INFO" "--- STAGE 3: INSTALLING PROFESSIONAL SOFTWARE FROM AUR ---"
# Install AUR packages as the target user
sudo -u "$CHIMERA_USER" --preserve-env=CHIMERA_ROOT bash -c 'paru -S --noconfirm visual-studio-code-bin postman-bin lazygit obsidian signal-desktop lkrg-dkms opensnitch-ebpf-module opensnitch btrfs-assistant btrfs-assistant-grub sddm-sugar-candy-git'
log "SUCCESS" "AUR software suite installed."

#--------------------------------------------------------------------------------
# STAGE 4: DESKTOP, DEV, AND SECURITY SUITE (OFFICIAL REPOS)
#--------------------------------------------------------------------------------
log "INFO" "--- STAGE 4: INSTALLING DESKTOP ENVIRONMENT AND CORE APPLICATIONS ---"
pacman -S --noconfirm \
    jq \
    bibata-cursor-theme fastfetch zsh-theme-powerlevel10k \
    neovim wireshark-qt keepassxc zeal docker \
    vim chromium firefox hyprland sddm kitty waybar rofi mako swaybg swaylock \
    pipewire wireplumber pavucontrol thunar mpv btop networkmanager network-manager-applet \
    blueman tlp mousepad grim slurp cliphist loupe evince \
    ttf-jetbrains-mono-nerd papirus-icon-theme zsh zsh-completions zsh-syntax-highlighting zsh-autosuggestions \
    qemu-full virt-manager dnsmasq ebtables libguestfs \
    apparmor tor privoxy aide bubblewrap bleachbit macchanger iptables \
    gparted cdrtools snapper btrfs-progs audit falco \
    inotify-tools rsync pacman-contrib # Added pacman-contrib for checkupdates
log "SUCCESS" "Desktop environment and core applications installed."

#--------------------------------------------------------------------------------
# STAGE 5: SYSTEM AND USER SERVICE CONFIGURATION
#--------------------------------------------------------------------------------
log "INFO" "--- STAGE 5: ENABLING SYSTEM SERVICES AND CONFIGURING THEME/USER ---"
# Enable services
systemctl enable sddm.service
systemctl enable NetworkManager.service
# Only enable bluetooth if drivers were installed
if [[ "$install_wifi" =~ ^([yY])$ ]]; then
    systemctl enable bluetooth.service
fi
systemctl enable tlp.service
systemctl enable libvirtd.service
systemctl enable docker.service
systemctl enable tor.service
systemctl enable apparmor.service
systemctl enable opensnitchd.service
systemctl enable fstrim.timer

# Configure SDDM theme
log "INFO" "Configuring SDDM theme..."
mkdir -p /etc/sddm.conf.d
cat <<EOF > /etc/sddm.conf.d/theme.conf
[Theme]
Current=sugar-candy
EOF

# Configure User
usermod -aG libvirt,docker "$CHIMERA_USER"
chsh -s /bin/zsh "$CHIMERA_USER"

# Setup directories and wallpaper
mkdir -p /usr/share/backgrounds/chimera
wget -qO /usr/share/backgrounds/chimera/chimera-wallpaper.png https://www.kali.org/images/wallpapers/kali-dragon-16x9.png
mkdir -p "$HOME_DIR/Pictures"
chown -R "$CHIMERA_USER":"$CHIMERA_USER" "$HOME_DIR/Pictures"

# Configure BTRFS Snapshots (if applicable)
if [ "$(findmnt -no FSTYPE /)" = 'btrfs' ]; then
    log "INFO" "Configuring BTRFS snapshot service (Snapper)..."
    snapper -c root create-config /
    systemctl enable snapper-timeline.timer
    systemctl enable snapper-cleanup.timer
    sed -i 's/TIMELINE_LIMIT_HOURLY=\"10\"/TIMELINE_LIMIT_HOURLY=\"5\"/' /etc/snapper/configs/root
    sed -i 's/TIMELINE_LIMIT_DAILY=\"10\"/TIMELINE_LIMIT_DAILY=\"7\"/' /etc/snapper/configs/root
fi
log "SUCCESS" "System services enabled, theme and user configured."

#--------------------------------------------------------------------------------
# STAGE 6: CALLING SPECIALIZED MODULES (HARDENING, AUDIT/FALCO)
#--------------------------------------------------------------------------------
log "INFO" "--- STAGE 6: APPLYING SYSTEM HARDENING AND AUDITING ---"
bash "$CHIMERA_ROOT/scripts/modules/hardening_system.sh"
bash "$CHIMERA_ROOT/scripts/modules/install_audit_falco.sh"

#--------------------------------------------------------------------------------
# STAGE 7: FINAL SYSTEM CONFIGURATIONS
#--------------------------------------------------------------------------------
log "INFO" "--- STAGE 7: APPLYING FINAL SYSTEM CONFIGURATIONS ---"
# Privoxy -> Tor Forwarding
echo "forward-socks5 / 127.0.0.1:9050 ." >> /etc/privoxy/config

# Firefox Hardening (create profile and basic user.js)
log "INFO" "Applying basic Firefox hardening..."
sudo -u "$CHIMERA_USER" firefox --headless --createprofile "default-release" >/dev/null 2>&1
PROFILE_DIR=$(find "$HOME_DIR/.mozilla/firefox/" -name "*.default-release")
if [ -n "$PROFILE_DIR" ]; then
    cat <<'EOF' > "$PROFILE_DIR/user.js"
user_pref("toolkit.telemetry.enabled", false);
user_pref("privacy.resistFingerprinting", true);
user_pref("media.peerconnection.enabled", false);
EOF
    chown "$CHIMERA_USER":"$CHIMERA_USER" "$PROFILE_DIR/user.js"
else
    log "WARN" "Could not find Firefox profile directory to apply user.js."
fi

# Copy custom scripts (guardian-cli, update-chimera, etc.)
log "INFO" "Installing custom system utilities..."
cp "$CHIMERA_ROOT/scripts/guardian-cli.sh" /usr/local/bin/guardian-cli
cp "$CHIMERA_ROOT/scripts/update-chimera" /usr/local/bin/update-chimera
cp "$CHIMERA_ROOT/scripts/sandbox-run.sh" /usr/local/bin/sandbox-run
chmod +x /usr/local/bin/*

log "SUCCESS" "Final system configurations applied."

#--------------------------------------------------------------------------------
# STAGE 8: CREATE MOTD FOR FINALIZATION
#--------------------------------------------------------------------------------
log "INFO" "Creating welcome message for next login..."
cat <<'EOF' > /etc/motd
################################################################
#     Welcome to Chimera Guardian Arch (Base Installed)        #
################################################################
#                                                              #
#  ‼️  ACTION REQUIRED: Reboot and run 'make finalize'         #
#                                                              #
#  to complete the system hardening and configuration linking. #
#                                                              #
################################################################
EOF

log "SUCCESS" "Base system installation phase completed."