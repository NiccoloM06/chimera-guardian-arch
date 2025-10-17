#!/usr/bin/env bash
set -euo pipefail

# =======================================================================================
#  POST-INSTALL HOOK | CHIMERA GUARDIAN ARCH
#  This script runs automatically after the main 'make install' process.
#  Add any custom, non-critical setup tasks here.
# =======================================================================================

# --- Source the shared library ---
# Provides logging functions. Assumes the main install script sets CHIMERA_ROOT.
if [ -f "$CHIMERA_ROOT/scripts/lib.sh" ]; then
    source "$CHIMERA_ROOT/scripts/lib.sh"
else
    # Fallback logger if lib.sh isn't available yet (shouldn't happen in normal flow)
    log() { echo "[HOOK] [$1] $*"; }
fi

log "INFO" "--- Running Post-Installation Hook ---"

# --- Add Your Custom Commands Below ---

# Example: Pre-download AUR packages cache for offline use (optional)
# log "INFO" "Pre-downloading AUR package sources..."
# sudo -u "$CHIMERA_USER" paru -Sw --noconfirm btrfs-assistant lkrg-dkms opensnitch # Add desired AUR packages

# Example: Clean pacman cache
# log "INFO" "Cleaning pacman cache..."
# sudo pacman -Scc --noconfirm

log "SUCCESS" "Post-Installation Hook completed."