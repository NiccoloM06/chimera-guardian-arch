#!/usr/bin/env bash
set -euo pipefail

# =======================================================================================
#  POST-UPDATE HOOK | CHIMERA GUARDIAN ARCH
#  This script runs automatically after 'make update'.
#  Its primary job is to update the AIDE integrity baseline.
# =======================================================================================

# --- Source the shared library ---
# Provides logging functions. Assumes CHIMERA_ROOT is available or script is run from root.
source "$(dirname "$0")/../scripts/lib.sh"

# --- Verify correct execution context ---
# This hook is generally called by the Makefile after sudo update-chimera runs.
# Double-check root privileges just in case.
if [ "$(id -u)" -ne 0 ]; then
    log "ERROR" "This script requires root privileges to update the AIDE database."
    exit 1
fi

log "INFO" "--- Running Post-Update Hook ---"

# --- Update AIDE Baseline ---
log "INFO" "Updating AIDE integrity baseline..."
# Run aide --update to compare the current state with the old db and create a new db.
aide --update

# Promote the newly generated database to be the active one.
mv -f /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
log "SUCCESS" "AIDE baseline updated successfully."

# --- Add Your Custom Post-Update Commands Below ---

# Example: Clean pacman cache after updates
# log "INFO" "Cleaning pacman cache..."
# pacman -Scc --noconfirm

log "SUCCESS" "Post-Update Hook completed."