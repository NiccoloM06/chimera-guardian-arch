#!/usr/bin/env bash
# =======================================================================================
#  CARICATORE DI CONFIGURAZIONI COMUNI | CHIMERA GUARDIAN ARCH
#  Carica variabili definite in file di configurazione condivisi.
# =======================================================================================

# Carica prima la libreria di logging per poter registrare eventuali errori
source "$(dirname "$0")/logger.sh"

# --- Carica il File di Configurazione Comune ---
COMMON_CONF_FILE="$CHIMERA_ROOT/config/.common.conf"

if [ -f "$COMMON_CONF_FILE" ]; then
    log "INFO" "Caricamento delle configurazioni comuni da $COMMON_CONF_FILE..."
    source "$COMMON_CONF_FILE"
    log "SUCCESS" "Configurazioni comuni caricate."
else
    log "WARN" "File di configurazione comune ($COMMON_CONF_FILE) non trovato. Verranno usati i valori di default."
fi

# --- Aggiungere qui la logica per caricare altre configurazioni globali se necessario ---
# Ad esempio, caricare configurazioni specifiche per l'host da config-overrides/
# HOSTNAME_CONF_FILE="$CHIMERA_ROOT/config-overrides/$(hostname).conf"
# if [ -f "$HOSTNAME_CONF_FILE" ]; then
#     log "INFO" "Caricamento delle sovrascritture specifiche per l'host..."
#     source "$HOSTNAME_CONF_FILE"
# fi