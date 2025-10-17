#!/usr/bin/env bash
# =======================================================================================
#  LIBRERIA DI LOGGING CENTRALIZZATA | CHIMERA GUARDIAN ARCH
#  Fornisce funzioni di logging standardizzate con colori e timestamp.
# =======================================================================================

# --- Variabili Globali Fondamentali ---
# Definisce la root del progetto per riferimenti ai percorsi
export CHIMERA_ROOT="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../.."
# Definisce il file di log corrente (basato sulla data)
export LOG_FILE="$CHIMERA_ROOT/logs/chimera-$(date +%F).log"

# --- Caricamento Variabili d'Ambiente da .env ---
if [ -f "$CHIMERA_ROOT/.env" ]; then
    # Carica le variabili definite dall'utente (es. THEME, CHIMERA_USER)
    source "$CHIMERA_ROOT/.env"
else
    # Se .env non esiste, lancia un errore critico (lo script validate_env.sh dovrebbe prevenirlo)
    echo -e "\033[1;31m[ERR]\033[0m File .env non trovato. Eseguire la configurazione iniziale." >&2
    exit 1
fi

# --- Codici Colore ANSI ---
export GREEN='\033[1;32m'
export YELLOW='\033[1;33m'
export RED='\033[1;31m'
export BLUE='\033[1;34m'
export NC='\033[0m' # No Color

# --- Funzione di Logging Avanzata ---
# Stampa messaggi formattati sulla console e li aggiunge al file di log.
# Uso: log "LIVELLO" "Messaggio"
# Livelli: INFO, SUCCESS, WARN, ERROR
log() {
  local level="$1"; shift
  local msg="$*"
  local ts
  ts=$(date +"%Y-%m-%d %H:%M:%S")

  local color
  case "$level" in
    INFO) color="$BLUE" ;;
    SUCCESS) color="$GREEN" ;;
    WARN) color="$YELLOW" ;;
    ERROR) color="$RED" ;;
    *) color="$NC" ;;
  esac

  # Scrive sia su stdout/stderr che sul file di log
  echo -e "[$ts] ${color}[$level]${NC} $msg" | tee -a "$LOG_FILE" ${1:+"$( [[ "$level" == "ERROR" ]] && echo >&2 )"}
}

# --- Funzione di Rollback (Definizione base) ---
# Questa funzione viene chiamata dal trap in caso di errore negli script principali.
rollback() {
  log "ERROR" "Errore critico rilevato durante l'operazione. Avvio del rollback..."
  # Qui possono essere aggiunte azioni di ripristino specifiche.
  # Ad esempio, potrebbe chiamare lo script rollback-system.sh.
  log "ERROR" "Operazione fallita. Sistema potenzialmente in stato inconsistente. Controllare il log: $LOG_FILE"
  exit 1
}

# --- Trap per la Gestione degli Errori ---
# Assicura che la funzione 'rollback' venga chiamata in caso di errore non gestito.
trap 'rollback' ERR