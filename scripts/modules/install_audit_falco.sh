#!/usr/bin/env bash
set -euo pipefail

# =======================================================================================
#  FALCO & AUDITD INSTALLATION MODULE | CHIMERA GUARDIAN ARCH
#  Installa e configura il sistema di auditing syscall.
#  Inteso per essere chiamato da 'install_system.sh'.
# =======================================================================================

# --- Carica la libreria condivisa ---
# shellcheck source=../lib.sh
source "$(dirname "$0")/../lib.sh"

# --- Verifica il contesto di esecuzione ---
if [ "$(id -u)" -ne 0 ]; then
    log "ERROR" "Questo script deve essere eseguito come root o con sudo."
    exit 1
fi

log "INFO" "--- Installazione e Configurazione di Auditd e Falco ---"

# --- 1. Installazione Pacchetti ---
log "INFO" "Installazione dei pacchetti audit, falco..."
# Installa auditd (necessario per Falco) e Falco stesso
pacman -S --noconfirm audit falco

# --- 2. Configurazione di Auditd ---
log "INFO" "Configurazione di auditd..."
# Abilita il servizio auditd
systemctl enable auditd.service
# Applica una configurazione di base (potrebbe essere personalizzata ulteriormente)
# Esempio: assicurarsi che le regole siano caricate all'avvio
# (La configurazione di default di Arch è solitamente adeguata per Falco)

# --- 3. Configurazione di Falco ---
log "INFO" "Configurazione di Falco..."
# Abilita il servizio Falco
systemctl enable falco.service

# (Opzionale) Copia le regole personalizzate se esistono nel progetto
FALCO_RULES_SRC="$CHIMERA_ROOT/config/falco/custom-rules.yaml"
FALCO_RULES_DEST="/etc/falco/rules.d/99-chimera-custom.yaml"
if [ -f "$FALCO_RULES_SRC" ]; then
    log "INFO" "Copia delle regole personalizzate di Falco..."
    cp "$FALCO_RULES_SRC" "$FALCO_RULES_DEST"
fi

# --- 4. Avvio dei Servizi ---
log "INFO" "Avvio dei servizi auditd e falco..."
# È importante avviare auditd prima di Falco
systemctl start auditd.service
systemctl start falco.service

log "SUCCESS" "Auditd e Falco installati, configurati e avviati."