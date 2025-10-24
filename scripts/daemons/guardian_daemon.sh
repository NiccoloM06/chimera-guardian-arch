#!/usr/bin/env bash
set -euo pipefail

# =======================================================================================
#  GUARDIAN DAEMON v1.5 | CHIMERA GUARDIAN ARCH (Omega Base)
#  Monitors critical services and security state, writing JSON status.
# =======================================================================================

# --- Source Library (Essential for log function and CHIMERA_ROOT) ---
# Assuming it runs via systemd, make path robust or define in service file
# shellcheck source=../core/logger.sh
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../core/logger.sh" || { echo "[ERR] Cannot load logger.sh"; exit 1; }

# --- Global Variables ---
STATE_FILE="/run/chimera/state.json"
GUARDIAN_CTL_STATUS_FILE="/tmp/guardian_status" # File where guardian-cli writes the profile
CHECK_INTERVAL=10 # Seconds

# --- Ensure /run directory exists ---
mkdir -p "$(dirname "$STATE_FILE")"
log "INFO" "Guardian Daemon starting..."

# --- Main Monitoring Loop ---
while true; do
    # --- Initialize Status Variables ---
    current_profile="Unknown"
    lkrg_status="INACTIVE"
    opensnitch_status="INACTIVE"
    falco_status="INACTIVE"
    falco_alerts_last_interval=0
    overall_status="SECURE" # Assume secure by default

    # --- Read Current Security Profile ---
    if [ -f "$GUARDIAN_CTL_STATUS_FILE" ]; then
        # Read only the first line to get the status, ignoring potential color codes
        current_profile=$(head -n 1 "$GUARDIAN_CTL_STATUS_FILE" | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g")
    fi

    # --- Check Critical Service Status ---
    if systemctl is-active --quiet lkrg &>/dev/null; then lkrg_status="ACTIVE"; else overall_status="WARN"; fi
    if systemctl is-active --quiet opensnitchd &>/dev/null; then opensnitch_status="ACTIVE"; else overall_status="WARN"; fi
    if systemctl is-active --quiet falco &>/dev/null; then falco_status="ACTIVE"; else overall_status="WARN"; fi

    # --- Check Recent Falco Alerts ---
    # Note: Requires Falco logging to journald at 'warning' or higher
    if command -v journalctl &>/dev/null; then
        # Count lines containing "Rule:" with priority warning or higher in the last interval
        falco_alerts_last_interval=$(journalctl -u falco --since "${CHECK_INTERVAL} seconds ago" -p warning --no-pager | grep -c "Rule:")
        if [ "$falco_alerts_last_interval" -gt 0 ]; then
            overall_status="ALERT"
            log "WARN" "Detected $falco_alerts_last_interval Falco alert(s) in the last interval."
            # Trigger logic (reading triggers.yml) could be added here in future versions
        fi
    else
        log "WARN" "journalctl not found, cannot check Falco alerts."
    fi

    # Ensure overall status reflects inactive critical services even if no Falco alerts
    [[ "$overall_status" != "ALERT" ]] && [[ "$lkrg_status" != "ACTIVE" || "$opensnitch_status" != "ACTIVE" || "$falco_status" != "ACTIVE" ]] && overall_status="WARN"

    # --- Write JSON State File ---
    # Use jq for reliable JSON creation
    jq -n \
      --arg status "$overall_status" \
      --arg profile "$current_profile" \
      --argjson alerts "$falco_alerts_last_interval" \
      --arg lkrg "$lkrg_status" \
      --arg opensnitch "$opensnitch_status" \
      --arg falco "$falco_status" \
      '{
          "timestamp": "'$(date -u --iso-8601=seconds)'",
          "overall_status": $status,
          "security_profile": $profile,
          "alerts_last_interval": $alerts,
          "services": {
            "lkrg": $lkrg,
            "opensnitch": $opensnitch,
            "falco": $falco
          }
       }' > "$STATE_FILE"

    # Wait for the next check interval
    sleep "$CHECK_INTERVAL"
done