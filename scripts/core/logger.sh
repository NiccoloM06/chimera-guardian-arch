#!/usr/-bin/env bash
# =======================================================================================
#  LIBRERIA CORE & LOGGER | CHIMERA GUARDIAN ARCH (Versione Corretta)
#  Fornisce logging strutturato, gestione errori con rollback, variabili globali.
# =======================================================================================

# --- Variabili Globali Fondamentali ---
_lib_script_dir="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
export CHIMERA_ROOT="${_lib_script_dir}/../.."

_current_date=$(date +%F)
export LOG_FILE="$CHIMERA_ROOT/logs/chimera-install-${_current_date}.log"

# --- Caricamento Variabili d'Ambiente da .env ---
# shellcheck source=../../.env
if [ -f "$CHIMERA_ROOT/.env" ]; then
    set -a # Esporta automaticamente le variabili caricate
    # shellcheck disable=SC1090
    source "$CHIMERA_ROOT/.env"
    set +a
else
    echo -e "\033[1;31m[ERR]\033[0m File .env non trovato. Copia .env.example in .env e configuralo." >&2
    exit 1
fi

# --- Codici Colore ANSI ---
export GREEN='\033[1;32m'
export YELLOW='\033[1;33m'
export RED='\033[1;31m'
export BLUE='\033[1;34m'
export NC='\033[0m' # No Color

# --- Funzione di Logging Avanzata (CORRETTA) ---
# Uso: log "LIVELLO" "Messaggio"
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

  # Assicura che la directory dei log esista
  mkdir -p "$(dirname "$LOG_FILE")"

  # Costruisci il messaggio di log
  local log_message
  log_message="[$ts] ${color}[$level]${NC} $msg"

  # Scrivi sul file di log
  echo -e "$log_message" >> "$LOG_FILE"

  # Scrivi sulla console
  # Importante: scrivi su stderr (>&2) solo se è un errore.
  if [[ "$level" == "ERROR" ]]; then
      echo -e "$log_message" >&2
  else
      echo -e "$log_message"
  fi
}

# --- Controllo Dipendenze ---
check_dep() {
  command -v "$1" >/dev/null 2_>&1 || {
    log "ERROR" "Dipendenza '$1' non trovata. Impossibile continuare."
    exit 1
  }
}

# --- Funzione di Rollback (Definizione base) ---
rollback() {
  local exit_code=$?
  log "ERROR" "Errore critico rilevato (Codice: $exit_code). Avvio del rollback automatico..."
  
  if command -v "$CHIMERA_ROOT/scripts/ops/rollback.sh" &> /dev/null; then
      log "WARN" "Tentativo di ripristino dall'ultimo backup delle configurazioni..."
      local target_user="${SUDO_USER:-$USER}"
      if [ "$target_user" != "root" ]; then
          sudo -u "$target_user" "$CHIMERA_ROOT/scripts/ops/rollback.sh" --auto-confirm || log "ERROR" "Script di rollback delle configurazioni fallito."
      else
           "$CHIMERA_ROOT/scripts/ops/rollback.sh" --auto-confirm || log "ERROR" "Script di rollback delle configurazioni fallito."
      fi
  fi
  
  log "ERROR" "Operazione fallita. Sistema potenzialmente in stato inconsistente. Controlla il log: $LOG_FILE"
}

# --- Trap per la Gestione degli Errori ---
trap 'rollback' ERR INT TERM