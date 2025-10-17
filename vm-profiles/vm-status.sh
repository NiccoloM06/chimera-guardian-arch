#!/usr/bin/env bash
set -euo pipefail

# =======================================================================================
#  VM STATUS UTILITY | CHIMERA GUARDIAN ARCH
#  Lists running virtual machines managed by libvirt and their status.
# =======================================================================================

# --- Source the shared library ---
# Provides logging functions.
source "$(dirname "$0")/../scripts/lib.sh"

# --- Check for libvirt tools ---
check_dep "virsh"

log "INFO" "--- Querying Libvirt for Running VM Status ---"

# Get a list of running domain IDs and names
running_vms=$(virsh list --state-running --name)

if [ -z "$running_vms" ]; then
    log "SUCCESS" "No virtual machines are currently running."
    exit 0
fi

# --- Display Header ---
printf "%-20s %-10s %-10s %-10s\n" "VM Name" "State" "CPU(s)" "Memory(Current)"
printf "%-20s %-10s %-10s %-10s\n" "--------------------" "----------" "----------" "---------------"

# --- Loop through running VMs and get details ---
while IFS= read -r vm_name; do
    if [ -z "$vm_name" ]; then continue; fi # Skip empty lines

    # Get basic domain info (State)
    state=$(virsh dominfo "$vm_name" | grep '^State:' | awk '{print $2}')
    
    # Get vCPU count
    vcpus=$(virsh dominfo "$vm_name" | grep '^CPU(s):' | awk '{print $2}')
    
    # Get current memory allocation (might differ from max if ballooning)
    # dommemstat provides current usage if balloon driver is active
    current_mem_kb=$(virsh dommemstat "$vm_name" --current | grep 'actual' | awk '{print $2}')
    if [ -z "$current_mem_kb" ]; then
        # Fallback to max memory if current isn't available
        current_mem_kb=$(virsh dominfo "$vm_name" | grep '^Max memory:' | awk '{print $3}')
    fi
    # Convert KB to MB for readability
    current_mem_mb=$((current_mem_kb / 1024))M

    printf "%-20s %-10s %-10s %-10s\n" "$vm_name" "$state" "$vcpus" "${current_mem_mb}"

done <<< "$running_vms"

echo ""
log "INFO" "VM status query complete."