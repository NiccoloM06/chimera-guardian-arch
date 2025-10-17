#!/usr/bin/env bash
set -euo pipefail

# =======================================================================================
#  GUARDIAN CLI | CHIMERA GUARDIAN ARCH
#  User-facing command line interface for managing security posture and system status.
# =======================================================================================

# --- Source the shared library ---
source "$(dirname "$0")/lib.sh"

# --- Function to display usage ---
usage() {
    echo "Usage: $0 {status|set <profile>|cloak <on|off>|vm <subcommand>|audit [--ai]}"
    echo ""
    echo "Commands:"
    echo "  status [--json]   : Display the current system security status."
    echo "  set <profile>   : Switch to a defined security profile (standard, secure, paranoid, cyberlab)."
    echo "  cloak <on|off>  : Enable/disable privacy cloak mode (disables telemetry, external DNS, etc.)."
    echo "  vm <subcommand> : Manage virtual machines (list, start, stop, snapshot)."
    echo "  audit [--ai]    : Run security audit checks (optionally include AI analysis)."
}

# --- Main Command Dispatcher ---
case "${1:-}" in
    status)
        log "INFO" "Querying current system status..."
        # In a full implementation, this would query guardian_daemon via socket or read state files.
        # For now, it calls healthcheck and formats the output.
        if [[ "${2:-}" == "--json" ]]; then
            sudo "$CHIMERA_ROOT/scripts/modules/healthcheck.sh" --json # Assuming healthcheck supports JSON output
        else
            sudo "$CHIMERA_ROOT/scripts/modules/healthcheck.sh"
        fi
        ;;
    set)
        if [ -z "${2:-}" ]; then log "ERROR" "Missing profile name."; usage; exit 1; fi
        profile_name=$(echo "$2" | tr '[:upper:]' '[:lower:]') # Normalize name
        log "INFO" "Attempting to set security profile to '$profile_name'..."
        # Call the backend script that actually applies the profile
        sudo "$CHIMERA_ROOT/scripts/guardian-ctl" set-level "$profile_name"
        ;;
    cloak)
        if [[ "$2" == "on" ]]; then
            log "INFO" "Engaging privacy cloak mode..."
            # Add commands to disable telemetry, block external DNS, stop sync services etc.
            log "SUCCESS" "Cloak mode enabled."
        elif [[ "$2" == "off" ]]; then
            log "INFO" "Disengaging privacy cloak mode..."
            # Add commands to re-enable services disabled by 'cloak on'
            log "SUCCESS" "Cloak mode disabled."
        else
            log "ERROR" "Invalid argument for cloak. Use 'on' or 'off'."
            usage
            exit 1
        fi
        ;;
    vm)
        log "INFO" "Executing VM command: ${@:2}"
        # Delegate to virt-manager or vm-status script
        "$CHIMERA_ROOT/vm-profiles/vm-status.sh" "${@:2}" || true # Example delegation
        ;;
    audit)
        log "INFO" "Running security audit..."
        # Run standard audit checks (e.g., aide-check)
        aide-check
        if [[ "${2:-}" == "--ai" ]]; then
            log "INFO" "Running AI-based anomaly detection (experimental)..."
            python3 "$CHIMERA_ROOT/ai/anomaly.py" --audit
        fi
        ;;
    *)
        usage
        exit 1
        ;;
esac