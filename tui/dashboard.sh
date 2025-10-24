#!/usr/bin/env bash
set -euo pipefail

# =======================================================================================
#  TUI CONTROL CENTER v1.5 | CHIMERA GUARDIAN ARCH (Omega Base)
#  Provides an interactive terminal dashboard using 'gum'.
# =======================================================================================

# --- Source the shared library ---
# shellcheck source=../scripts/core/logger.sh
source "$(dirname "$0")/../scripts/core/logger.sh"

# --- Dependency Check ---
check_dep "gum"
check_dep "jq"

# --- Helper to display status ---
display_status() {
    local state_file="/run/chimera/state.json"
    if [ -f "$state_file" ]; then
        # Extract data from JSON, providing fallbacks for missing keys
        local status profile alerts lkrg osnitch falco ts
        status=$(jq -r '.overall_status // "UNKNOWN"' "$state_file")
        profile=$(jq -r '.security_profile // "Unknown"' "$state_file")
        alerts=$(jq -r '.alerts_last_interval // "?"' "$state_file")
        lkrg=$(jq -r '.services.lkrg // "?"' "$state_file")
        osnitch=$(jq -r '.services.opensnitch // "?"' "$state_file")
        falco=$(jq -r '.services.falco // "?"' "$state_file")
        ts=$(jq -r '.timestamp // "N/A"' "$state_file")

        local status_color="$BLUE" # Default to INFO
        [[ "$status" == "WARN" ]] && status_color="$YELLOW"
        [[ "$status" == "ALERT" ]] && status_color="$RED"
        [[ "$status" == "SECURE" ]] && status_color="$GREEN"

        gum style --padding "0 1" --border double --border-foreground "$status_color" \
          "Status: ${status_color}${status}${NC} | Profile: ${profile} | Alerts(10s): ${alerts} | LKRG: ${lkrg} | O'Snitch: ${osnitch} | Falco: ${falco} | As of: ${ts}"
    else
        gum style --padding "0 1" --border double --border-foreground "$YELLOW" "Status: UNKNOWN (Guardian Daemon inactive or not found)"
    fi
    echo "" # Newline after status
}

# --- Main Application Loop ---
while true; do
    clear
    gum style --border normal --margin "1" --padding "1 2" --border-foreground "$BLUE" "👑 Chimera Guardian Arch - Control Center 👑 v$(cat "$CHIMERA_ROOT/VERSION")"
    
    display_status # Show current status at the top

    OPTION=$(gum choose \
        "🚀 Update System" \
        "🛡️ Change Security Level" \
        "🩺 Run Health Check" \
        "💾 Perform Backup" \
        "🔄 Perform Rollback" \
        "🖥️ Manage VMs" \
        "🎨 Switch Theme" \
        "⚙️ Link Configs" \
        "🧹 Clean Build Files" \
        "📜 View Install Log" \
        "🚪 Exit")

    case "$OPTION" in
        "🚀 Update System")
            log "INFO" "Initiating system update via TUI..."
            if gum confirm "Run full system update?"; then
                # Run 'make update' which in turn calls 'overlord update'
                gum spin --spinner dot --title "Updating system (check logs for details)..." -- \
                    make update
                log "SUCCESS" "Update process finished."
            else
                log "INFO" "Update cancelled."
            fi
            gum input --placeholder "Press [Enter] to return..." > /dev/null
            ;;
        "🛡️ Change Security Level")
            log "INFO" "Selecting new security level..."
            LEVEL=$(gum choose "Standard" "Secure" "Paranoid" "CyberLab")
            if [ -n "$LEVEL" ]; then
                level_cmd=$(echo "$LEVEL" | tr '[:upper:]' '[:lower:]')
                log "INFO" "Setting security level to '$level_cmd'..."
                # Call the corresponding zsh function (requires zsh_functions to be loaded)
                # or call guardian-cli directly
                sudo "$CHIMERA_ROOT/scripts/guardian-cli.sh" set "$level_cmd"
                gum input --placeholder "Level changed. Press [Enter]..." > /dev/null
            else
                log "INFO" "Security level change cancelled."
            fi
            ;;
        "🩺 Run Health Check")
            log "INFO" "Initiating system health check..."
            make healthcheck
            gum input --placeholder "Health check finished. Press [Enter]..." > /dev/null
            ;;
        "💾 Perform Backup")
            log "INFO" "Initiating configuration backup..."
            gum spin --spinner dot --title "Creating backup snapshot..." -- \
                make backup
            log "SUCCESS" "Backup process finished."
            gum input --placeholder "Backup complete. Press [Enter]..." > /dev/null
            ;;
        "🔄 Perform Rollback")
            log "WARN" "Initiating configuration rollback..."
            if gum confirm "This will overwrite current configs with the LATEST backup. Proceed?"; then
                gum spin --spinner dot --title "Restoring from backup..." -- \
                    make rollback
                log "SUCCESS" "Rollback process finished."
            else
                log "INFO" "Rollback cancelled."
            fi
            gum input --placeholder "Rollback process finished. Press [Enter]..." > /dev/null
            ;;
        "🖥️ Manage VMs")
            log "INFO" "Checking VM Status..."
            "$CHIMERA_ROOT/vm-profiles/vm-status.sh"
            if gum confirm "Create a new VM?"; then
                 VM_PROFILE=$(gum choose "disposable" "work" "tor" "cyberlab")
                 if [ -n "$VM_PROFILE" ]; then
                     log "INFO" "Creating VM '$VM_PROFILE'..."
                     # Use the overlord command for consistency
                     gum spin --spinner dot --title "Creating VM '$VM_PROFILE'..." -- \
                        "$CHIMERA_ROOT/overlord" vm "$VM_PROFILE"
                     log "SUCCESS" "VM creation process finished."
                 else
                     log "INFO" "VM creation cancelled."
                 fi
            fi
            gum input --placeholder "Press [Enter] to return..." > /dev/null
            ;;
        "🎨 Switch Theme")
            log "INFO" "Selecting new theme..."
            AVAILABLE_THEMES=($(ls "$CHIMERA_ROOT/themes"))
            THEME_CHOICE=$(printf "%s\n" "${AVAILABLE_THEMES[@]}" | gum filter --placeholder "Select theme...")

            if [ -n "$THEME_CHOICE" ]; then
                log "INFO" "Switching theme to '$THEME_CHOICE'..."
                gum spin --spinner dot --title "Applying theme '$THEME_CHOICE'..." -- \
                    make theme theme="$THEME_CHOICE"
                log "SUCCESS" "Theme switched. Restart Waybar/Kitty/Rofi if needed."
            else
                log "INFO" "Theme switch cancelled."
            fi
            gum input --placeholder "Theme switched. Press [Enter]..." > /dev/null
            ;;
        "⚙️ Link Configs")
             log "INFO" "Re-linking configuration files..."
             if gum confirm "This will re-apply symlinks for the current theme. Proceed?"; then
                 make link
                 log "SUCCESS" "Configuration files re-linked."
             else
                 log "INFO" "Linking cancelled."
             fi
             gum input --placeholder "Linking process finished. Press [Enter]..." > /dev/null
            ;;
        "🧹 Clean Build Files")
             log "INFO" "Cleaning temporary build files..."
             make clean
             log "SUCCESS" "Temporary files cleaned."
             gum input --placeholder "Cleaning complete. Press [Enter]..." > /dev/null
            ;;
        "📜 View Install Log")
             log "INFO" "Displaying the main installation log..."
             # Use 'gum pager' for a better viewing experience
             gum pager < "$LOG_FILE"
             # No confirmation needed, pager handles exit
            ;;
        "🚪 Exit")
            log "INFO" "Exiting TUI Control Center."
            break # Exit the while loop
            ;;
        *)
            # Handles Esc or Ctrl+C in gum choose
            log "INFO" "Exiting TUI Control Center."
            break
            ;;
    esac
done

clear # Clear the screen on exit