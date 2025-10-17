#!/usr/bin/env bash
set -euo pipefail

# =======================================================================================
#  POST-REBOOT FINALIZATION MODULE | CHIMERA GUARDIAN ARCH
#  Initializes AIDE and performs final cleanup. Called by 'make finalize'.
# =======================================================================================

# --- Source the shared library ---
source "$(dirname "$0")/../lib.sh"

# --- Verify correct execution context ---
if [ "$(id -u)" -ne 0 ]; then
    log "ERROR" "This script must be run as root or with sudo."
    exit 1
fi

log "INFO" "######################################################################"
log "INFO" "### 🚀 FINALIZATION SCRIPT FOR CHIMERA GUARDIAN ARCH               ###"
log "INFO" "######################################################################"
echo ""
log "INFO" "This script will complete the hardening process by creating the"
log "INFO" "system integrity baseline with AIDE."
echo ""
read -p "Are you ready to continue? (y/N) " response
if [[ "$response" =~ ^([yY])$ ]]; then

    # --- AIDE INITIALIZATION ---
    echo ""
    log "INFO" "--- 📸 Stage 1: Initializing AIDE (Advanced Intrusion Detection Environment) ---"
    log "INFO" "Creating the initial system snapshot. This is a critical step and may take several minutes..."
    
    # Check if AIDE is installed
    check_dep "aide"
    
    # Generate the initial database
    aide --init
    
    # Promote the new database to be the official one
    mv -f /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
    
    log "SUCCESS" "AIDE database created successfully."
    echo ""
    log "WARN" "‼️  CRITICAL ACTION IMMINENT: SECURE THE AIDE BASELINE"
    log "WARN" "The file '/var/lib/aide/aide.db.gz' is your system's 'anchor of trust'."
    log "WARN" "You MUST copy it NOW to a secure, write-protected external medium (e.g., a locked SD card or a CD-R)."
    log "WARN" "Consult the SYSTEM_GUIDE.md for detailed instructions on creating this secure medium."
    read -p "Press [Enter] to acknowledge and continue..."

    # --- FINAL CLEANUP ---
    echo ""
    log "INFO" "--- 🧹 Stage 2: Final Cleanup ---"
    # Remove the welcome message, as finalization is complete
    if [ -f "/etc/motd" ]; then
        rm -f /etc/motd
        log "SUCCESS" "Welcome message removed."
    fi
    # Remove the finalize service itself if it exists (legacy check, might not be needed)
    if [ -f "/etc/systemd/system/chimera-finalize.service" ]; then
        systemctl disable chimera-finalize.service >/dev/null 2>&1 || true
        rm -f /etc/systemd/system/chimera-finalize.service
        rm -f /etc/chimera.conf
        log "SUCCESS" "Automatic finalization service removed."
    fi
    sleep 1

    echo ""
    log "SUCCESS" "🎉 Finalization complete!"
    log "INFO" "Your Chimera Guardian Arch system is now fully operational."
    log "INFO" "Remember to install essential Firefox add-ons (uBlock Origin, NoScript)."

else
    log "INFO" "Aborted."
fi