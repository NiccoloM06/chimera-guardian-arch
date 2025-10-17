#!/usr/bin/env bash
set -euo pipefail

# =======================================================================================
#  UNIVERSAL INSTALLER & DISPATCHER | CHIMERA GUARDIAN ARCH (Monarch Edition)
#  This script is the main entry point for all installation and management tasks.
# =======================================================================================

# --- Source the shared library ---
# Provides logging functions, color codes, CHIMERA_ROOT, and error handling.
# The path must be relative to this script's location.
# shellcheck source=scripts/lib.sh
source "$(dirname "$0")/scripts/lib.sh"

# --- Function to display usage information ---
usage() {
    echo "Usage: $0 [FLAG]"
    echo "This is the main entrypoint for the Chimera Guardian Arch framework."
    echo ""
    echo "Flags:"
    echo "  --fresh          : Runs the main system installation (requires sudo)."
    echo "  --finalize       : Runs the post-reboot finalization and links configs (requires sudo)."
    echo "  --link           : (Re)creates symbolic links for your configuration files."
    echo "  --backup         : Creates a compressed snapshot of your existing ~/.config directory."
    echo "  --vm <profile>   : Creates a VM from a profile (e.g., tor, work, disposable)."
    echo "  -y, --unattended : Runs a full, non-interactive installation from start to finish (requires sudo)."
    echo "  -h, --help       : Displays this help message."
    echo ""
    echo "If run without flags, it will prompt for a fresh installation."
}

# --- Unattended Installation Function ---
run_unattended_install() {
    log "WARN" "STARTING UNATTENDED INSTALLATION (--unattended)."
    log "WARN" "This script will attempt to automatically modify /etc/default/grub and /etc/fstab."
    log "WARN" "This is potentially risky. Proceed only on a clean, fresh installation."
    read -r -p "Continue with the fully automated installation? (y/N) " response
    if [[ ! "$response" =~ ^([yY])$ ]]; then
        log "INFO" "Aborted."
        exit 0
    fi

    # --- Stage 1: Base Installation ---
    log "INFO" "Running base installation..."
    "$CHIMERA_ROOT/scripts/modules/install_system.sh"

    # --- Stage 2: Automate Manual Steps ---
    log "INFO" "Automating critical modifications..."
    # Check if files exist before attempting modification
    if [ -f "/etc/default/grub" ]; then
        sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/&lsm=landlock,lockdown,yama,apparmor,bpf /' /etc/default/grub
        grub-mkconfig -o /boot/grub/grub.cfg
    else
        log "WARN" "/etc/default/grub not found. Skipping bootloader parameter addition."
    fi
    if [ -f "/etc/fstab" ]; then
        sed -i 's/relatime/noatime/' /etc/fstab
    else
         log "WARN" "/etc/fstab not found. Skipping fstab optimization."
    fi
    log "SUCCESS" "Attempted modification of /etc/default/grub and /etc/fstab."

    # --- Stage 3: Create the One-Shot Finalization Service ---
    log "INFO" "Creating the automatic finalization service..."
    # Save the project path and user name for the service
    cat <<EOF > /etc/chimera.conf
CHIMERA_PROJECT_PATH="$PWD"
CHIMERA_USER="$SUDO_USER"
EOF
    cat <<'EOF' > /etc/systemd/system/chimera-finalize.service
[Unit]
Description=Chimera Guardian Arch - Post-Reboot Finalization
Wants=network-online.target # Wait for network connectivity
After=network-online.target default.target

[Service]
Type=oneshot
# Ensure script is executed with correct user and path
ExecStart=/bin/bash -c 'source /etc/chimera.conf && cd "$CHIMERA_PROJECT_PATH" && sudo -u "$CHIMERA_USER" --preserve-env=CHIMERA_ROOT "$CHIMERA_PROJECT_PATH/install.sh" --finalize'
# Clean up after successful execution
ExecStartPost=/bin/rm -f /etc/systemd/system/chimera-finalize.service /etc/chimera.conf
RemainAfterExit=yes

[Install]
WantedBy=default.target
EOF
    systemctl enable chimera-finalize.service
    log "SUCCESS" "Service 'chimera-finalize.service' created and enabled."

    # --- Stage 4: Reboot ---
    log "INFO" "Base installation is complete. The system will reboot in 10 seconds."
    log "INFO" "Upon restart, finalization will run automatically in the background."
    sleep 10
    reboot
}

# --- Initial Checks (Integrity and Environment) ---
log "INFO" "Verifying script integrity..."
if ! sha256sum -c --status "$CHIMERA_ROOT/checksums.txt"; then
    log "ERROR" "Checksum validation failed! Core scripts may have been tampered with. Aborting."
    exit 1
fi
log "SUCCESS" "All scripts passed integrity check."

log "INFO" "Validating .env configuration..."
"$CHIMERA_ROOT/scripts/modules/validate_env.sh"
log "SUCCESS" ".env configuration is valid."


# --- Interactive Prompt for New Users ---
if [ $# -eq 0 ]; then
    log "INFO" "Welcome to the Chimera Guardian Arch installer."
    read -r -p "No flags provided. Would you like to start a fresh installation? (y/N) " response
    if [[ "$response" =~ ^([yY])$ ]]; then
        # Re-execute the script with the --fresh flag and sudo
        log "INFO" "Restarting with sudo for fresh installation..."
        sudo "$0" --fresh
        exit 0
    else
        log "INFO" "Aborted. Run with '--help' to see all available options."
        exit 0
    fi
fi

# --- CLI-style Argument Parsing ---
case "${1:-}" in
  --fresh)
    if [ "$(id -u)" -ne 0 ]; then log "ERROR" "The --fresh flag must be run with sudo."; exit 1; fi
    # Execute pre-install hook
    bash "$CHIMERA_ROOT/hooks/pre-install.sh"
    # Execute main installation module
    "$CHIMERA_ROOT/scripts/modules/install_system.sh"
    # Execute post-install hook
    bash "$CHIMERA_ROOT/hooks/post-install.sh"
    ;;
  --finalize)
    if [ "$(id -u)" -ne 0 ]; then log "ERROR" "The --finalize flag must be run with sudo."; exit 1; fi
    # Execute finalization module
    "$CHIMERA_ROOT/scripts/modules/finalize_system.sh"
    log "INFO" "Linking configuration files for user: $SUDO_USER..."
    # Run the linker as the original user, not root
    sudo -u "$SUDO_USER" --preserve-env=CHIMERA_ROOT "$CHIMERA_ROOT/link-configs.sh"
    ;;
  --link)
    "$CHIMERA_ROOT/link-configs.sh"
    ;;
  --backup)
    "$CHIMERA_ROOT/scripts/backup-configs.sh"
    ;;
  --vm)
    if [ -z "${2:-}" ]; then log "ERROR" "The --vm flag requires a profile."; exit 1; fi
    "$CHIMERA_ROOT/vm-profiles/create-vm.sh" "$2"
    ;;
  -y|--unattended)
    if [ "$(id -u)" -ne 0 ]; then log "ERROR" "The --unattended flag must be run with sudo."; exit 1; fi
    # Execute pre-install hook
    bash "$CHIMERA_ROOT/hooks/pre-install.sh"
    # Run the unattended install function
    run_unattended_install
    # Note: Post-install hook is implicitly covered by the finalize service
    ;;
  -h|--help)
    usage
    ;;
  *)
    log "ERROR" "Invalid flag: $1"
    usage
    exit 1
    ;;
esac

log "SUCCESS" "Operation completed."