#!/usr/bin/env bash
set -euo pipefail

# =======================================================================================
#  DEPENDENCY CHECKER | CHIMERA GUARDIAN ARCH (v49+)
#  Verifies and installs essential framework dependencies.
# =======================================================================================

# Source the logger, but don't fail if unavailable during initial bootstrap
if [ -f "$(dirname "$0")/logger.sh" ]; then
    # shellcheck source=logger.sh
    source "$(dirname "$0")/logger.sh"
else
    # Minimal fallback logger
    log() { echo "[$1] $*"; }
    RED='\033[1;31m'; NC='\033[0m'
    log_error() { echo -e "${RED}[ERR]${NC}  $*" >&2; } # Define log_error for fallback
fi

# Package map: command -> pacman package name
# This helps resolve cases where the command name differs from the package name (e.g., systemctl -> systemd)
declare -A pkgs=(
  [git]="git"
  [curl]="curl"
  [tar]="tar"
  [rsync]="rsync"
  [systemctl]="systemd"
  [journalctl]="systemd"
  [aide]="aide"
  [falco]="falco"
  [auditd]="audit"
  [gpg]="gnupg"
  [age]="age"
  [logrotate]="logrotate"
  [jq]="jq"
  [pacman-contrib]="pacman-contrib" # Provides checkupdates
  [python]="python"
  [iptables]="iptables"
  [macchanger]="macchanger"
  [ufw]="ufw"
  [wget]="wget" # Used in install_system for wallpaper
  [paru]="paru" # Check if paru exists (installed separately by install_system)
  # opensnitchd / lkrg are installed via paru later, not checked here
)

# Function to check and install a single dependency
ensure_dependency() {
  local cmd="$1"
  local pkg="${pkgs[$cmd]:-$cmd}" # Default to command name if not in the map

  # Check if command exists in PATH
  if command -v "$cmd" >/dev/null 2>&1; then
    log "SUCCESS" "Dependency found: $cmd"
    return 0
  fi

  # If command doesn't exist, check if the corresponding package is already installed
  # This handles cases like 'systemctl' provided by the 'systemd' package
  if pacman -Q "$pkg" &>/dev/null; then
      log "SUCCESS" "Dependency found (via package $pkg): $cmd "
      # Special check for paru which might be installed but not in PATH yet
      if [[ "$cmd" == "paru" ]] && [[ ! -x "/usr/bin/paru" ]]; then
           log "WARN" "'paru' package installed but command not found in PATH. Assuming OK for now..."
           # Allow continuing, paru installation is handled later if missing/broken
           return 0
      elif [[ "$cmd" != "paru" ]]; then
           # If package installed but command missing, something is odd, but maybe install fixes it
           log "WARN" "Package '$pkg' installed, but command '$cmd' not found. Check PATH. Will attempt reinstall."
           # Let the install proceed, it might fix links or PATH issues
      fi
  fi

  # If neither command nor package found, attempt installation
  log "WARN" "Missing dependency: $cmd. Attempting to install package '$pkg'..."

  # Check for root privileges before using pacman
  if [ "$(id -u)" -ne 0 ]; then
      log "ERROR" "Root privileges are required to install '$pkg'. Run the main script with sudo."
      return 1 # Don't exit immediately, let the main loop decide
  fi

  # Install the required package (--needed installs only if missing)
  sudo pacman -S --needed --noconfirm "$pkg" || {
    log "ERROR" "Failed to install package '$pkg'. Please try installing it manually."
    return 1
  }

  # Re-check if the command is now available after installation
  if ! command -v "$cmd" >/dev/null 2>&1; then
      # Re-check package for systemd cases where command might still not be obvious
      if ! pacman -Q "$pkg" &>/dev/null; then
          log "ERROR" "Even after attempted install, package '$pkg' for '$cmd' could not be installed."
          return 1
      fi
       # If package installed but command still missing, log warning but don't fail yet
       log "WARN" "Package '$pkg' installed, but command '$cmd' still not found. Check PATH or package contents."
  fi
  log "SUCCESS" "Dependency '$cmd' installed successfully via package '$pkg'."
}

# --- Main Dependency Check Logic ---
main() {
  log "INFO" "--- Verifying Essential Framework Dependencies ---"
  # Extended list of critical commands required by the framework's scripts
  local commands_to_check=(
      git curl tar rsync systemctl journalctl aide falco auditd jq wget
      gpg age logrotate pacman-contrib python iptables macchanger ufw
      # opensnitchd lkrg (Installed via AUR, checked later if paru exists)
      # bats (Only needed for 'make test', not critical for install)
  )
  local all_deps_ok=true
  for c in "${commands_to_check[@]}"; do
    # Call ensure_dependency and update all_deps_ok if it fails (returns non-zero)
    ensure_dependency "$c" || all_deps_ok=false
  done

  # Explicitly check for paru, but don't fail if missing, just warn
  if ! command -v paru >/dev/null 2>&1; then
       log "WARN" "AUR helper 'paru' not found. AUR packages will be skipped unless installed manually."
       # Don't set all_deps_ok=false here, AUR is optional for core functionality
   else
       log "SUCCESS" "Dependency found: paru"
   fi

  # Final check: exit if any *essential* dependency failed
  if [ "$all_deps_ok" = false ]; then
      log "ERROR" "One or more essential dependencies could not be installed. Cannot continue."
      exit 1 # Exit with error code
  else
      log "SUCCESS" "All essential dependencies are met."
  fi
}

# Execute main function only if the script is called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi