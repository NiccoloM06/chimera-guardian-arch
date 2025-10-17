#!/usr/bin/env bash
set -euo pipefail

# =======================================================================================
#  GUARDIAN DAEMON | CHIMERA GUARDIAN ARCH
#  Monitora in tempo reale lo stato di sicurezza del sistema e aggiorna un file di stato.
#  Progettato per essere eseguito come servizio systemd.
# =======================================================================================

# --- Carica la libreria condivisa ---
# Assume che CHIMERA_ROOT sia definito globalmente o che lo script sia eseguito dalla root del progetto.
# Per un servizio systemd, è meglio definire CHIMERA_ROOT esplicitamente se necessario.
# SOURCE_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
# source "$SOURCE_DIR/../core/logger.sh" # Usa logger.sh per il logging

# --- Variabili Globali ---
STATE_FILE="/run/chimera/state.json"
STATUS_FILE_GUARDIAN_CTL="/tmp/guardian_status" # File dove guardian-ctl scrive il profilo attivo
CHECK_INTERVAL=10 # Secondi tra ogni controllo

# --- Funzione di Logging Semplificata per il Daemon ---
# Usa logger per scrivere sul log principale del framework
log_daemon() {
  local level="$1"; shift
  local msg="$*"
  # Assicurati che logger.sh sia caricato
  if command -v log >/dev/null 2>&1; then
    log "$level" "[Daemon] $msg"
  else
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] [Daemon] $msg" >> "/var/log/chimera_daemon.log" # Fallback log
  fi
}

# --- Funzione Principale di Monitoraggio ---
monitor_system() {
    local overall_status="SECURE" # Assume lo stato sicuro di default
    local falco_alerts=0
    local lkrg_status="INACTIVE"
    local opensnitch_status="INACTIVE"
    local current_profile="Unknown"

    # 1. Controlla lo stato di LKRG
    if systemctl is-active --quiet lkrg; then
        lkrg_status="ACTIVE"
    else
        overall_status="WARN"
        log_daemon "WARN" "Servizio LKRG non attivo."
    fi

    # 2. Controlla lo stato di OpenSnitch
    if systemctl is-active --quiet opensnitchd; then
        opensnitch_status="ACTIVE"
    else
        overall_status="WARN"
        log_daemon "WARN" "Servizio OpenSnitch non attivo."
    fi

    # 3. Controlla i log di Falco per alert recenti (ultimi $CHECK_INTERVAL secondi)
    # Nota: Questo richiede che Falco logghi su journald
    if command -v journalctl >/dev/null 2>&1; then
        falco_alerts=$(journalctl -u falco --since "${CHECK_INTERVAL} seconds ago" -p warning --no-pager | grep -c "Rule:")
        if [ "$falco_alerts" -gt 0 ]; then
            overall_status="ALERT"
            log_daemon "ALERT" "Rilevati $falco_alerts alert da Falco negli ultimi $CHECK_INTERVAL secondi."
            # Qui si potrebbe integrare la logica per leggere triggers.yml ed eseguire azioni
        fi
    else
        log_daemon "WARN" "journalctl non trovato, impossibile controllare gli alert di Falco."
    fi
    
    # 4. Legge il profilo di sicurezza corrente da guardian-ctl
    if [ -f "$STATUS_FILE_GUARDIAN_CTL" ]; then
        current_profile=$(cat "$STATUS_FILE_GUARDIAN_CTL")
    fi

    # Scrive lo stato aggregato nel file JSON
    cat <<EOF > "$STATE_FILE"
{
  "timestamp": "$(date -u --iso-8601=seconds)",
  "overall_status": "$overall_status",
  "security_profile": "$current_profile",
  "alerts_last_interval": $falco_alerts,
  "services": {
    "lkrg": "$lkrg_status",
    "opensnitch": "$opensnitch_status"
  }
}
EOF
}

# --- Loop Principale del Daemon ---
log_daemon "INFO" "Avvio del Guardian Daemon in modalità di monitoraggio."
mkdir -p "$(dirname "$STATE_FILE")" # Assicura che la directory /run/chimera esista

while true; do
    monitor_system
    sleep "$CHECK_INTERVAL"
done