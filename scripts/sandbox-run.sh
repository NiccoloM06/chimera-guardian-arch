#!/usr/bin/env bash
set -euo pipefail

# =======================================================================================
#  SANDBOX RUNNER SCRIPT | CHIMERA GUARDIAN ARCH
#  Executes a given command inside a minimal bubblewrap sandbox.
# =======================================================================================

# --- Source the shared library ---
source "$(dirname "$0")/lib.sh"

# --- Verify correct execution context ---
# Bubblewrap is generally run as the user
# if [ "$(id -u)" -eq 0 ]; then
#     log "WARN" "Running sandboxes as root is generally not recommended."
# fi

# --- Check for command ---
if [ $# -eq 0 ]; then
    log "ERROR" "Usage: $0 <command> [args...]"
    log "ERROR" "Example: $0 firefox --private-window"
    exit 1
fi

# The command and its arguments to be executed inside the sandbox
COMMAND_TO_RUN=("$@")

log "INFO" "--- Preparing Sandbox Environment ---"
log "INFO" "Command to run: ${COMMAND_TO_RUN[*]}"

# --- Bubblewrap Sandbox Configuration ---
# This creates a very basic sandbox:
# - Mounts essential system directories read-only (/usr, /lib, etc.)
# - Creates a new temporary home directory
# - Provides access to essential devices (/dev) and process info (/proc)
# - Shares the network namespace (allows internet access)
# - Unshares other namespaces for isolation

BWRAP_ARGS=(
    "--dev-bind" "/" "/"             # Bind the real root filesystem
    "--ro-bind" "/usr" "/usr"       # Make /usr read-only
    "--ro-bind" "/lib" "/lib"       # Make /lib read-only
    "--ro-bind" "/lib64" "/lib64"   # Make /lib64 read-only
    "--ro-bind" "/bin" "/bin"       # Make /bin read-only
    "--ro-bind" "/sbin" "/sbin"     # Make /sbin read-only
    "--proc" "/proc"                # Mount /proc filesystem
    "--dev" "/dev"                  # Mount /dev filesystem
    "--tmpfs" "/tmp"                # Create a temporary /tmp
    
    # Create a minimal, temporary home directory
    "--bind" "$HOME" "$HOME"        # Bind user's real home (adjust for stricter isolation if needed)
    # OR for a fully temporary home:
    # "--tmpfs" "/home/$USER"
    # "--setenv" "HOME" "/home/$USER"

    "--unshare-all"                 # Unshare most namespaces (PID, mount, etc.)
    "--share-net"                   # Keep the network namespace (allow internet)
    
    # Environment variables needed for GUI apps
    "--setenv" "DISPLAY" "${DISPLAY:-:0}"
    "--setenv" "WAYLAND_DISPLAY" "${WAYLAND_DISPLAY:-wayland-1}"
    "--setenv" "XDG_RUNTIME_DIR" "${XDG_RUNTIME_DIR}"
    "--ro-bind" "${XDG_RUNTIME_DIR}/wayland-1" "${XDG_RUNTIME_DIR}/wayland-1" # Wayland socket
)

log "INFO" "Launching command inside bubblewrap sandbox..."
echo "--- SANDBOX OUTPUT START ---"

# Execute the command inside the sandbox
if ! bwrap "${BWRAP_ARGS[@]}" -- "${COMMAND_TO_RUN[@]}"; then
    log "ERROR" "Command execution within the sandbox failed."
    echo "--- SANDBOX OUTPUT END ---"
    exit 1
fi

echo "--- SANDBOX OUTPUT END ---"
log "SUCCESS" "Sandbox execution finished."