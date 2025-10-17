#!/usr/bin/env bash
set -euo pipefail

# =======================================================================================
#  TUI CONTROL CENTER | CHIMERA GUARDIAN ARCH
#  Provides an interactive terminal dashboard for managing the framework.
# =======================================================================================

# --- Source the shared library ---
# Provides logging functions, color variables, and CHIMERA_ROOT.
source "$(dirname "$0")/../scripts/lib.sh"

# --- Dependency Check ---
# Ensure 'gum' is installed. It should be, via the main installer.
check_dep "gum"

# --- Main Application Loop ---
while true; do
    # Clear the screen for a fresh display
    clear

    # Display the header using gum's styling
    gum style --border normal --margin "1" --padding "1 2" --border-foreground "$BLUE" "👑 Chimera Guardian Arch - Control Center 👑 v$(cat "$CHIMERA_ROOT/VERSION")"

    # Present the main menu options using gum choose
    OPTION=$(gum choose \
        "🚀 Update System" \
        "🛡️ Change Security Level" \
        "🩺 Run Health Check" \
        "💾 Perform Backup" \
        "🔄 Perform Rollback" \
        "🖥️ Manage VMs" \
        "🎨 Switch Theme" \
        "🚪 Exit")

    # Handle the user's choice
    case "$OPTION" in
        "🚀 Update System")
            log "INFO" "Initiating system update via TUI..."
            # Show a spinner while the command runs in the background
            gum spin --spinner dot --title "Updating system (check logs for details)..." -- \
                make update
            log "SUCCESS" "Update process finished."
            gum confirm "Return to main menu?" || break # Ask to continue or exit
            ;;

        "🛡️ Change Security Level")
            log "INFO" "Selecting new security level..."
            LEVEL=$(gum choose "Standard" "Secure" "Paranoid" "CyberLab")
            if [ -n "$LEVEL" ]; then
                # Normalize level name to lowercase for the command
                level_cmd=$(echo "$LEVEL" | tr '[:upper:]' '[:lower:]')
                log "INFO" "Setting security level to '$level_cmd'..."
                # Execute the corresponding function defined in zsh_functions
                # We need to run it in a zsh context if sourced there, or call guardian-cli directly
                sudo "$CHIMERA_ROOT/scripts/guardian-cli.sh" set "$level_cmd"
                gum confirm "Return to main menu?" || break
            else
                log "INFO" "Security level change cancelled."
            fi
            ;;

        "🩺 Run Health Check")
            log "INFO" "Initiating system health check..."
            # Execute the health check directly
            make healthcheck
            gum confirm "Return to main menu?" || break
            ;;

        "💾 Perform Backup")
            log "INFO" "Initiating configuration backup..."
            gum spin --spinner dot --title "Creating backup snapshot..." -- \
                make backup
            log "SUCCESS" "Backup process finished."
            gum confirm "Return to main menu?" || break
            ;;

        "🔄 Perform Rollback")
            log "WARN" "Initiating configuration rollback..."
            if gum confirm "This will overwrite your current configurations with the latest backup. Proceed?"; then
                gum spin --spinner dot --title "Restoring from backup..." -- \
                    make rollback
                log "SUCCESS" "Rollback process finished."
            else
                log "INFO" "Rollback cancelled."
            fi
            gum confirm "Return to main menu?" || break
            ;;

        "🖥️ Manage VMs")
            log "INFO" "Checking VM Status..."
            # Display VM status using the dedicated script
            "$CHIMERA_ROOT/vm-profiles/vm-status.sh"
            # Offer options to create a VM
            if gum confirm "Do you want to create a new VM?"; then
                 VM_PROFILE=$(gum choose "disposable" "work" "tor" "cyberlab")
                 if [ -n "$VM_PROFILE" ]; then
                     log "INFO" "Creating VM '$VM_PROFILE'..."
                     gum spin --spinner dot --title "Creating VM '$VM_PROFILE'..." -- \
                        make vm profile="$VM_PROFILE"
                     log "SUCCESS" "VM creation process finished."
                 else
                     log "INFO" "VM creation cancelled."
                 fi
            fi
            gum confirm "Return to main menu?" || break
            ;;

        "🎨 Switch Theme")
            log "INFO" "Selecting new theme..."
            # Dynamically list available themes from the themes directory
            AVAILABLE_THEMES=($(ls "$CHIMERA_ROOT/themes"))
            THEME_CHOICE=$(printf "%s\n" "${AVAILABLE_THEMES[@]}" | gum filter --placeholder "Select theme...")

            if [ -n "$THEME_CHOICE" ]; then
                log "INFO" "Switching theme to '$THEME_CHOICE'..."
                gum spin --spinner dot --title "Applying theme '$THEME_CHOICE'..." -- \
                    make theme theme="$THEME_CHOICE"
                log "SUCCESS" "Theme switched successfully. You may need to restart Waybar/Kitty."
            else
                log "INFO" "Theme switch cancelled."
            fi
            gum confirm "Return to main menu?" || break
            ;;

        "🚪 Exit")
            log "INFO" "Exiting TUI Control Center."
            break # Exit the while loop
            ;;

        *)
            # Handles case where user presses Esc or Ctrl+C
            log "INFO" "Exiting TUI Control Center."
            break
            ;;
    esac
done

clear # Clear the screen on exit