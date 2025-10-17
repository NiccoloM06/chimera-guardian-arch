#!/usr/bin/env bash
set -euo pipefail

# =======================================================================================
#  PRE-BACKUP HOOK | CHIMERA GUARDIAN ARCH
#  Questo script viene eseguito automaticamente prima di 'make backup'.
#  Usalo per fermare temporaneamente servizi che potrebbero interferire con un backup consistente.
# =======================================================================================

# --- Carica la libreria condivisa ---
# Fornisce le funzioni di logging. Assume che CHIMERA_ROOT sia disponibile o che lo script sia eseguito dalla root.
source "$(dirname "$0")/../scripts/lib.sh"

# --- Verifica il contesto di esecuzione ---
# Questo hook è chiamato dal Makefile prima che venga eseguito lo script di backup.
# Alcune azioni potrebbero richiedere privilegi di root.
# if [ "$(id -u)" -ne 0 ]; then
#     log "ERROR" "Questo hook potrebbe richiedere privilegi di root per fermare alcuni servizi."
# fi

log "INFO" "--- Esecuzione dell'Hook Pre-Backup ---"

# --- Aggiungi qui i tuoi comandi personalizzati ---

# Esempio: Ferma il servizio libvirtd per assicurare che lo stato delle VM sia consistente.
# log "INFO" "Arresto temporaneo del servizio libvirtd..."
# sudo systemctl stop libvirtd.service
# sleep 2 # Attendi un paio di secondi per assicurarti che il servizio sia fermo

# Esempio: Ferma un database se è in esecuzione
# log "INFO" "Arresto temporaneo del servizio PostgreSQL..."
# sudo systemctl stop postgresql.service

log "SUCCESS" "Hook Pre-Backup completato. Il sistema è pronto per il backup."

# NOTA: I servizi fermati qui dovrebbero idealmente essere riavviati da un hook post-backup
#       oppure lo script di backup stesso dovrebbe gestire il riavvio dopo aver completato l'operazione.