#!/usr/bin/env bash
set -euo pipefail

# =======================================================================================
#  SYSTEM ROLLBACK SCRIPT | CHIMERA GUARDIAN ARCH
#  Restores user configuration files (~/.config) from the latest available backup.
# =======================================================================================

# --- Source the shared library ---
source "$(dirname "$0")/lib.sh"

# --- Define Variables ---
BACKUP_DIR="$HOME/.chimera_backups"
AUTO_CONFIRM=false

# --- Argument Parsing ---
if [[ "${1:-}" == "--auto-confirm" ]]; then
    AUTO_CONFIRM=true
    log "WARN" "Rollback initiated in automatic mode."
fi

# --- Main Logic ---
log "INFO" "--- Starting Configuration Rollback Procedure ---"

# Check if the backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    log "ERROR" "No backup directory found at '$BACKUP_DIR'."
    exit 1
fi

# Find the latest backup directory (based on timestamp in the name)
LATEST_BACKUP=$(ls -td -- "$BACKUP_DIR"/chimera-configs-backup-*.tar.gz | head -n 1)

if [ -z "$LATEST_BACKUP" ] || [ ! -f "$LATEST_BACKUP" ]; then
    log "ERROR" "No valid backup snapshots found in '$BACKUP_DIR'."
    exit 1
fi

log "INFO" "Latest backup snapshot found: $(basename "$LATEST_BACKUP")"

# --- Confirmation Step ---
if [ "$AUTO_CONFIRM" = false ]; then
    log "WARN" "This operation will overwrite your current ~/.config directory with the contents of the backup."
    read -p "Are you absolutely sure you want to proceed? (y/N) " response
    if [[ ! "$response" =~ ^([yY])$ ]]; then
        log "INFO" "Rollback aborted by user."
        exit 0
    fi
fi

# --- Restoration Process ---
log "INFO" "Restoring configurations from '$LATEST_BACKUP'..."

# Create a temporary directory for extraction
TMP_RESTORE_DIR=$(mktemp -d)
log "INFO" "Extracting backup to temporary location: $TMP_RESTORE_DIR"
tar -xzf "$LATEST_BACKUP" -C "$TMP_RESTORE_DIR"

# Use rsync to safely replace the current .config with the backup content
# --delete ensures files not in the backup are removed from the current config
log "INFO" "Synchronizing restored configuration to ~/.config..."
rsync -a --delete "$TMP_RESTORE_DIR/.config/" "$HOME/.config/"

# Clean up the temporary directory
rm -rf "$TMP_RESTORE_DIR"

log "SUCCESS" "Rollback complete. Your ~/.config directory has been restored from the latest backup."
log "INFO" "You may need to restart applications or log out/in for all changes to take effect."