#!/usr/bin/env bash
# =======================================================================================
#  SHARED LIBRARY | CHIMERA GUARDIAN ARCH
#  Provides common functions and environment variables for all framework scripts.
# =======================================================================================

# --- Global Variables ---
# Defines the project's root directory, allowing scripts to be run from anywhere.
export CHIMERA_ROOT="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/.."
# Defines the current log file path based on date.
export LOG_FILE="$CHIMERA_ROOT/logs/chimera-install-$(date +%F).log"

# --- Load Environment Variables ---
# Loads user-defined settings from the .env file. Crucial for user-specific configs.
if [ -f "$CHIMERA_ROOT/.env" ]; then
    source "$CHIMERA_ROOT/.env"
else
    # Critical error if .env is missing, as many scripts depend on CHIMERA_USER etc.
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
# Provides consistent, timestamped, and color-coded logging to both console and file.
# Usage: log "LEVEL" "Message" (Levels: INFO, SUCCESS, WARN, ERROR)
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
  
  # Log to file and console (stderr for errors).
  echo -e "[$ts] ${color}[$level]${NC} $msg" | tee -a "$LOG_FILE" ${1:+"$( [[ "$level" == "ERROR" ]] && echo >&2 )"}
}

# --- Dependency Checker ---
# Verifies if a command (dependency) exists in the system's PATH. Exits if not found.
# Usage: check_dep "git"
check_dep() {
  command -v "$1" >/dev/null 2>&1 || {
    log "ERROR" "Dependency '$1' not found. Please install it before proceeding."
    exit 1
  }
}

# --- Rollback Function ---
# This function is triggered by the 'trap' command if any script using this library exits
# due to an error ('set -e'). It attempts to perform cleanup or restore actions.
rollback() {
  log "ERROR" "A critical error occurred. Initiating automatic rollback procedures..."
  # Example Rollback Action: Restore latest config backup if available
  if command -v "$CHIMERA_ROOT/scripts/rollback-system.sh" &> /dev/null; then
      log "WARN" "Attempting to restore last configuration backup..."
      "$CHIMERA_ROOT/scripts/rollback-system.sh" --auto-confirm || log "ERROR" "Rollback script failed."
  fi
  # Add other rollback steps here (e.g., removing symlinks, disabling services).
  log "ERROR" "Operation failed. The system might be in an inconsistent state. Please check the log for details: $LOG_FILE"
  exit 1 # Ensure the script exits after rollback attempt.
}

# --- Trap for Error Handling ---
# Ensures the 'rollback' function is called automatically on any script error (exit code > 0)
# when 'set -e' is active.
trap 'rollback' ERR