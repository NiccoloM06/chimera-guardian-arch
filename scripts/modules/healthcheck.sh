#!/usr/bin/env bash
set -euo pipefail

# =======================================================================================
#  SYSTEM HEALTH CHECK MODULE | CHIMERA GUARDIAN ARCH
#  Verifica lo stato dei componenti di sicurezza critici e genera un report JSON.
#  Inteso per essere chiamato da 'make healthcheck' o dal Guardian Daemon.
# =======================================================================================

# --- Carica la libreria condivisa ---
# shellcheck source=../lib.sh
source "$(dirname "$0")/../lib.sh"

# --- Verifica il contesto di esecuzione ---
if [ "$(id -u)" -ne 0 ]; then
    log "ERROR" "Questo script deve essere eseguito come root o con sudo."
    exit 1
fi

log "INFO" "--- Inizio Controllo di Salute di Chimera Guardian Arch ---"

# --- Variabili per il report JSON ---
declare -A status
status["timestamp"]=$(date -u --iso-8601=seconds)
status["aide_status"]="UNKNOWN"
status["opensnitch_status"]="INACTIVE"
status["dnscrypt_status"]="INACTIVE"
status["tor_status"]="INACTIVE"
status["lkrg_status"]="INACTIVE"
status["falco_status"]="INACTIVE"
status["updates_pending"]="UNKNOWN"
status["security_profile"]="Unknown"

# --- 1. Controllo Stato AIDE (Verifica esistenza database) ---
log "INFO" "Controllo stato AIDE..."
if [ -f "/var/lib/aide/aide.db.gz" ]; then
    status["aide_status"]="BASELINE_PRESENT"
    log "SUCCESS" "Baseline AIDE trovata."
else
    status["aide_status"]="BASELINE_MISSING"
    log "WARN" "Baseline AIDE (/var/lib/aide/aide.db.gz) non trovata."
fi

# --- 2. Controllo Servizi Systemd ---
log "INFO" "Controllo stato dei servizi critici..."
declare -a services_to_check=("opensnitchd" "dnscrypt-proxy" "tor" "lkrg" "falco")
for service in "${services_to_check[@]}"; do
    service_key="${service/_/-}_status" # Es. dnscrypt_proxy -> dnscrypt_proxy_status
    if systemctl is-active --quiet "$service"; then
        status["$service_key"]="ACTIVE"
        log "SUCCESS" "Servizio $service: ATTIVO"
    else
        status["$service_key"]="INACTIVE"
        log "WARN" "Servizio $service: INATTIVO"
    fi
done

# --- 3. Controllo Aggiornamenti Pendenti ---
# Usa checkupdates (parte di pacman-contrib) per un controllo rapido
log "INFO" "Controllo aggiornamenti pendenti..."
if command -v checkupdates >/dev/null 2>&1; then
    updates_count=$(checkupdates | wc -l)
    status["updates_pending"]="$updates_count"
    if [ "$updates_count" -eq 0 ]; then
        log "SUCCESS" "Nessun aggiornamento pendente."
    else
        log "WARN" "$updates_count aggiornamenti di sistema pendenti."
    fi
else
    log "WARN" "'checkupdates' non trovato. Impossibile controllare gli aggiornamenti."
fi

# --- 4. Lettura Profilo di Sicurezza Corrente ---
log "INFO" "Lettura del profilo di sicurezza corrente..."
STATUS_FILE_GUARDIAN_CTL="/tmp/guardian_status"
if [ -f "$STATUS_FILE_GUARDIAN_CTL" ]; then
    status["security_profile"]=$(cat "$STATUS_FILE_GUARDIAN_CTL")
fi
log "INFO" "Profilo di Sicurezza Attuale: ${status["security_profile"]}"


# --- Generazione del Report JSON ---
log "INFO" "Generazione del report JSON..."
output_json=$(jq -n \
    --arg ts "${status['timestamp']}" \
    --arg aide "${status['aide_status']}" \
    --arg opensnitch "${status['opensnitch_status']}" \
    --arg dnscrypt "${status['dnscrypt_status']}" \
    --arg tor "${status['tor_status']}" \
    --arg lkrg "${status['lkrg_status']}" \
    --arg falco "${status['falco_status']}" \
    --argjson updates "${status['updates_pending']}" \
    --arg profile "${status['security_profile']}" \
    '{ timestamp: $ts, aide_status: $aide, services: { opensnitch: $opensnitch, dnscrypt: $dnscrypt, tor: $tor, lkrg: $lkrg, falco: $falco }, updates_pending: $updates, security_profile: $profile }'
)

# Salva il report in /run (RAM) per l'accesso da parte del daemon o altri strumenti
echo "$output_json" > /run/chimera/health.json

# Stampa il report formattato sulla console
echo "$output_json" | jq .

log "SUCCESS" "Controllo di salute completato. Report generato in /run/chimera/health.json"