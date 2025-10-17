#!/usr/bin/env bash
# Shared functions and environment library for the Chimera framework.

# --- Global Variables ---
# Defines the project's root directory
# SC2155 Fix: Declare separately
local _lib_script_dir
_lib_script_dir="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
export CHIMERA_ROOT="${_lib_script_dir}/../.."

# Defines the current log file path
# SC2155 Fix: Declare separately
local _current_date
_current_date=$(date +%F)
export LOG_FILE="$CHIMERA_ROOT/logs/chimera-${_current_date}.log"

# --- Load Environment Variables ---
# SC1091 Fix: Add source directive
# shellcheck source=../../.env
if [ -f "$CHIMERA_ROOT/.env" ]; then
    source "$CHIMERA_ROOT/.env"
else
    echo -e "\033[1;31m[ERR]\033[0m .env file not found. Please copy .env.example to .env and configure it." >&2
    exit 1
fi

# --- ANSI Color Codes ---
export GREEN='\033[1;32m'
export YELLOW='\033[1;33m'
export RED='\033[1;31m'
export BLUE='\033[1;34m'
export NC='\033[0m' # No Color

# --- Advanced Logging Function ---
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
  
  # Ensure the logs directory exists.
  mkdir -p "$(dirname "$LOG_FILE")"
  
  echo -e "[$ts] ${color}[$level]${NC} $msg" | tee -a "$LOG_FILE" ${1:+"$( [[ "$level" == "ERROR" ]] && echo >&2 )"}
}

# --- Dependency Checker ---
check_dep() {
  command -v "$1" >/dev/null 2>&1 || {
    log "ERROR" "Dependency '$1' not found. Please install it before proceeding."
    exit 1
  }
}

# --- Rollback Function ---
rollback() {
  log "ERROR" "A critical error occurred. Initiating automatic rollback procedures..."
  # Example Rollback Action: Restore latest config backup if available
  if command -v "$CHIMERA_ROOT/scripts/ops/rollback.sh" &> /dev/null; then
      log "WARN" "Attempting to restore last configuration backup..."
      "$CHIMERA_ROOT/scripts/ops/rollback.sh" --auto-confirm || log "ERROR" "Rollback script failed."
  fi
  log "ERROR" "Operation failed. The system might be in an inconsistent state. Please check the log for details: $LOG_FILE"
  exit 1 # Ensure the script exits after rollback attempt.
}

# --- Trap for Error Handling ---
trap 'rollback' ERR