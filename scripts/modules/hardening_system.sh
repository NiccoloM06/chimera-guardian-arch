#!/usr/bin/env bash
set -euo pipefail

# =======================================================================================
#  SYSTEM HARDENING MODULE | CHIMERA GUARDIAN ARCH
#  Applies specific hardening configurations (sysctl, journald, etc.).
#  Intended to be called by the main installation script.
# =======================================================================================

# --- Source the shared library ---
# shellcheck source=../lib.sh
source "$(dirname "$0")/../lib.sh"

# --- Verify correct execution context ---
if [ "$(id -u)" -ne 0 ]; then
    log "ERROR" "This script must be run as root or with sudo."
    exit 1
fi

log "INFO" "--- Applying System Hardening Configurations ---"

# --- Kernel Parameter Hardening (sysctl) ---
log "INFO" "Applying kernel parameter hardening via sysctl..."
cat <<EOF > /etc/sysctl.d/99-chimera-hardening.conf
# Enable TCP SYN cookie protection (mitigates SYN flood attacks)
net.ipv4.tcp_syncookies = 1

# Disable acceptance of ICMP redirects (potential MITM vector)
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Restrict access to kernel pointers in /proc (reduces info leaks)
kernel.kptr_restrict = 1

# Restrict ptrace scope (prevents non-child processes from ptrace-ing)
kernel.yama.ptrace_scope = 1

# Disable core dumps for SUID binaries
fs.suid_dumpable = 0
EOF
# Apply the new settings immediately
sysctl --system > /dev/null
log "SUCCESS" "Kernel parameters hardened."

# --- Journald Configuration (Volatile Logs) ---
log "INFO" "Configuring journald for volatile (RAM-only) logging..."
# Check if the line exists and uncomment/modify it, otherwise add it.
if grep -q "^#Storage=" /etc/systemd/journald.conf; then
    sed -i 's/^#Storage=.*$/Storage=volatile/' /etc/systemd/journald.conf
elif grep -q "^Storage=" /etc/systemd/journald.conf; then
    sed -i 's/^Storage=.*$/Storage=volatile/' /etc/systemd/journald.conf
else
    echo "Storage=volatile" >> /etc/systemd/journald.conf
fi
# Restart journald to apply the change
systemctl restart systemd-journald
log "SUCCESS" "Journald configured for volatile storage."

# --- Sudoers Configuration (Optional Enhancements) ---
# log "INFO" "Applying sudoers enhancements..."
# Example: Add timestamp logging for sudo commands
# echo 'Defaults log_output' >> /etc/sudoers.d/00-chimera-defaults
# echo 'Defaults timestamp_timeout=0' >> /etc/sudoers.d/00-chimera-defaults
# log "SUCCESS" "Sudoers enhancements applied."

# --- Webcam Blacklisting ---
log "INFO" "Applying webcam driver blacklist..."
cat <<EOF > /etc/modprobe.d/blacklist-webcam.conf
# Prevent common webcam drivers from loading automatically
blacklist uvcvideo
blacklist sonix_camera
blacklist gspca_main
blacklist stk11xx
blacklist pwc
EOF
log "SUCCESS" "Webcam drivers blacklisted."

# --- Mute-on-boot Service ---
log "INFO" "Configuring mute-on-boot service..."
cat <<'EOF' > /etc/systemd/system/mute-on-boot.service
[Unit]
Description=Mute all audio at boot
After=sound.target
[Service]
Type=oneshot
ExecStart=/usr/bin/amixer -q -c 0 sset Master,0 0% mute
ExecStart=/usr/bin/amixer -q -c 0 sset Capture,0 0% nocap
[Install]
WantedBy=multi-user.target
EOF
systemctl enable mute-on-boot.service >/dev/null 2>&1
log "SUCCESS" "Mute-on-boot service enabled."

log "SUCCESS" "System hardening configurations applied successfully."