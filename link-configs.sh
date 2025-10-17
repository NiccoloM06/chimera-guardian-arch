#!/usr/bin/env bash
set -euo pipefail

# =======================================================================================
#  CONFIGURATION LINKER SCRIPT | CHIMERA GUARDIAN ARCH
#  Creates symlinks from the framework's config/ and themes/ dirs to ~/.config.
#  Automatically backs up existing configurations.
# =======================================================================================

# --- Source the shared library ---
# Provides logging functions, colors, CHIMERA_ROOT, and theme variable ($THEME).
# shellcheck source=scripts/lib.sh
source "$(dirname "$0")/scripts/lib.sh"

# --- Argument Parsing ---
DRY_RUN=false
NO_BACKUP=false
if [[ "${1:-}" == "--dry-run" ]]; then DRY_RUN=true; log "WARN" "Running in --dry-run mode. No changes will be made."; fi
if [[ "${1:-}" == "--no-backup" ]]; then NO_BACKUP=true; log "WARN" "Running with --no-backup. Existing files will NOT be backed up."; fi

# --- Helper Function for Linking ---
# Creates a symlink, backing up the destination if it exists and is not a link.
link() {
  local src="$1"
  local dest="$2"
  
  # Ensure the source actually exists
  if [ ! -e "$src" ]; then
      log "WARN" "Source file/directory not found, skipping link: $src"
      return
  fi

  # Backup existing file/directory if it's not already a symlink and backup is enabled
  if [ "$NO_BACKUP" = false ] && [ -e "$dest" ] && [ ! -L "$dest" ]; then
      # SC2155 Fix: Declare separately
      local bak_dest
      bak_dest="${dest}.bak_$(date +%F_%T)"
      log "WARN" "Found existing config at '$dest'. Backing it up to '$bak_dest'."
      mv "$dest" "$bak_dest"
  fi

  # Perform linking or dry run
  if [ "$DRY_RUN" = true ]; then
    log "INFO" "[DRY RUN] Would link: $dest -> $src"
  else
    # Ensure the parent directory exists before linking
    mkdir -p "$(dirname "$dest")"
    # Create/overwrite the symbolic link
    ln -sf "$src" "$dest"
    log "SUCCESS" "🔗 Linked: $dest"
  fi
}

# --- Main Linking Process ---
log "INFO" "Starting configuration linking process..."
log "INFO" "Selected theme from .env: $THEME"

# --- 1. Link Base Configurations ---
log "INFO" "Linking base configuration files from 'config/'..."
BASE_CONFIG_DIR="$CHIMERA_ROOT/config"
for config_item in "$BASE_CONFIG_DIR"/*; do
    # Skip hidden files like .common.conf which are sourced, not linked directly
    [[ "$(basename "$config_item")" == .* ]] && continue
    
    config_name=$(basename "$config_item")
    link "$config_item" "$HOME/.config/$config_name"
done

# --- 2. Link Theme-Specific Configurations ---
log "INFO" "Applying theme-specific files from 'themes/$THEME/'..."
THEME_DIR="$CHIMERA_ROOT/themes/$THEME"
if [ ! -d "$THEME_DIR" ]; then
    log "ERROR" "Theme directory '$THEME_DIR' not found. Check the THEME variable in your .env file."
    exit 1
fi
if [ ! -f "$THEME_DIR/manifest.yml" ]; then
    log "WARN" "Theme manifest 'manifest.yml' not found in '$THEME_DIR'."
fi

# Link theme files, potentially overwriting base links where specified
for theme_file in "$THEME_DIR"/*; do
    target_name=$(basename "$theme_file")
    
    # Skip the manifest file itself
    [[ "$target_name" == "manifest.yml" ]] && continue
    
    # Determine the correct target path based on the file name
    case "$target_name" in
        kitty.conf)
            link "$theme_file" "$HOME/.config/kitty/theme.conf" # Kitty supports including theme files
            # Ensure the main kitty.conf includes this line: include ./theme.conf
            if [ -f "$HOME/.config/kitty/kitty.conf" ] && ! grep -q "include ./theme.conf" "$HOME/.config/kitty/kitty.conf"; then
                echo "include ./theme.conf" >> "$HOME/.config/kitty/kitty.conf"
            fi
            ;;
        rofi.rasi)
            # Rofi needs the theme file directly linked or imported
            link "$theme_file" "$HOME/.config/rofi/theme.rasi"
             # Update main rofi config to use the linked theme file
            if [ -f "$HOME/.config/rofi/config.rasi" ]; then
                 sed -i 's/^@theme .*/@theme "~\/.config\/rofi\/theme.rasi"/' "$HOME/.config/rofi/config.rasi"
            fi
            ;;
        waybar.css)
            # Waybar expects the style file at style.css
            link "$theme_file" "$HOME/.config/waybar/style.css"
            ;;
        *)
            log "WARN" "Unknown theme file type, skipping: $target_name"
            ;;
    esac
done

# --- 3. Link Zsh Functions & Powerlevel10k Config ---
log "INFO" "Linking Zsh functions and Powerlevel10k theme..."
link "$CHIMERA_ROOT/zsh_functions" "$HOME/.zsh_functions"
link "$CHIMERA_ROOT/.p10k.zsh" "$HOME/.p10k.zsh"

# --- 4. Ensure .zshrc Sources Functions ---
# Automatically add the source line to .zshrc if it doesn't exist
ZSHRC_FILE="$HOME/.zshrc"
SOURCE_LINE='[[ -f ~/.zsh_functions ]] && source ~/.zsh_functions'
if [ -f "$ZSHRC_FILE" ]; then
    if ! grep -qF -- "$SOURCE_LINE" "$ZSHRC_FILE" 2>/dev/null; then
        log "INFO" "Adding source line for custom functions to $ZSHRC_FILE..."
        echo -e "\n# Load Chimera Guardian Arch functions and aliases\n$SOURCE_LINE" >> "$ZSHRC_FILE"
    fi
else
    log "WARN" "$ZSHRC_FILE not found. Cannot automatically add source line."
fi

log "SUCCESS" "Configuration linking process complete."
if [ "$DRY_RUN" = true ]; then log "WARN" "Dry run finished. No actual changes were made."; fi