#!/usr/bin/env bash
set -euo pipefail

# =======================================================================================
#  ENVIRONMENT VALIDATION MODULE | CHIMERA GUARDIAN ARCH
#  Checks if the .env file exists and contains all required variables.
#  Called automatically by the Makefile before installation.
# =======================================================================================

# --- Source the shared library ---
# Need the logger and CHIMERA_ROOT
# shellcheck source=../lib.sh
source "$(dirname "$0")/../lib.sh"

log "INFO" "--- Validating Environment Configuration ---"

# --- 1. Check if .env file exists ---
ENV_FILE="$CHIMERA_ROOT/.env"
if [ ! -f "$ENV_FILE" ]; then
    log "ERROR" "Configuration file '.env' not found in project root."
    log "ERROR" "Please copy '.env.example' to '.env' and fill in your details."
    exit 1
fi
log "SUCCESS" ".env file found."

# --- 2. Check for Required Variables ---
# Define the variables that absolutely must be set in the .env file
required_vars=("CHIMERA_USER" "CHIMERA_HOSTNAME" "THEME")
missing_vars=false

log "INFO" "Checking for required variables in .env..."
for var_name in "${required_vars[@]}"; do
    # Use indirect expansion to check if the variable sourced from .env is empty
    if [ -z "${!var_name}" ]; then
        log "ERROR" "Required variable '$var_name' is missing or empty in '$ENV_FILE'."
        missing_vars=true
    fi
done

# --- 3. Final Verdict ---
if [ "$missing_vars" = true ]; then
    log "ERROR" "One or more required variables are missing. Please configure '$ENV_FILE'."
    exit 1
else
    log "SUCCESS" "All required environment variables are set."
fi

log "SUCCESS" "Environment validation passed."