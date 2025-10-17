#!/usr/bin/env bash
set -euo pipefail

# =======================================================================================
#  CONFIGURATION BACKUP SCRIPT | CHIMERA GUARDIAN ARCH
#  Creates a compressed tar.gz snapshot of the user's ~/.config directory.
# =======================================================================================

# --- Source the shared library ---
source "$(dirname "$0")/lib.sh"

# --- Define Variables ---
TARGET_DIR="$HOME/.config"
BACKUP_PARENT_DIR="$HOME/.chimera_backups" # Store backups in a dedicated hidden folder
BACKUP_FILE="$BACKUP_PARENT_DIR/chimera-configs-backup-$(date +%F_%H-%M-%S).tar.gz"

# --- Main Logic ---
log "INFO" "Creating a compressed snapshot of the ~/.config directory..."

# Ensure the backup parent directory exists
mkdir -p "$BACKUP_PARENT_DIR"

# Check if the target directory actually exists
if [ ! -d "$TARGET_DIR" ]; then
    log "WARN" "~/.config directory not found. Nothing to back up."
    exit 0
fi

# Create the compressed archive
log "INFO" "Compressing configurations..."
tar -czf "$BACKUP_FILE" -C "$HOME" .config

log "SUCCESS" "Backup snapshot created successfully at:"
echo "$BACKUP_FILE"

# Optional: Pruning old backups (e.g., keep only the last 5)
# log "INFO" "Pruning old backups (keeping the last 5)..."
# ls -tp "$BACKUP_PARENT_DIR" | grep '\.tar\.gz$' | tail -n +6 | xargs -I {} rm -- "$BACKUP_PARENT_DIR/{}"
# log "SUCCESS" "Old backups pruned."