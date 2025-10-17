#!/usr/bin/env bash
set -euo pipefail

# =======================================================================================
#  UNIVERSAL VM CREATOR | CHIMERA GUARDIAN ARCH
#  Creates a virtual machine based on a specified profile (.conf file).
# =======================================================================================

# --- Source the shared library ---
source "$(dirname "$0")/../scripts/lib.sh"

# --- Argument Validation ---
if [ -z "${1:-}" ]; then
    log "ERROR" "Usage: $0 <profile_name>"
    log "ERROR" "Example: $0 work"
    exit 1
fi

PROFILE_NAME="$1"
CONF_FILE="$CHIMERA_ROOT/vm-profiles/${PROFILE_NAME}.conf"

if [ ! -f "$CONF_FILE" ]; then
    log "ERROR" "VM profile '$PROFILE_NAME' not found at '$CONF_FILE'."
    exit 1
fi

# --- Load Profile Variables ---
# This sources variables like VM_NAME, VM_RAM, VM_TYPE, etc.
source "$CONF_FILE"
log "INFO" "Loaded profile: $PROFILE_NAME"

# --- Define Common Variables ---
STORAGE_PATH="$HOME/.local/share/libvirt/images"
BASE_IMAGE_URL="https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
BASE_IMAGE_NAME="debian-12-base.qcow2"
VM_DISK_PATH="${STORAGE_PATH}/${VM_NAME}.qcow2"

# --- Pre-flight Checks ---
# Check if a VM with the same name already exists to prevent conflicts.
if virsh dominfo "${VM_NAME}" >/dev/null 2>&1; then
    log "ERROR" "A VM with the name '${VM_NAME}' already exists. Please remove it first ('virsh undefine ${VM_NAME} --remove-all-storage') or choose a different name."
    exit 1
fi
mkdir -p "$STORAGE_PATH"

log "INFO" "### 🚀 Starting creation of VM: $VM_NAME ###"
echo "  - RAM:       ${VM_RAM} MB"
echo "  - vCPUs:     ${VM_VCPUS}"
echo "  - Disk Size: ${DISK_SIZE:-N/A (Disposable)}"
echo "  - Type:      ${VM_TYPE}"
echo ""

# --- Download Base Image (if it doesn't exist) ---
if [ ! -f "${STORAGE_PATH}/${BASE_IMAGE_NAME}" ]; then
    log "INFO" "📥 Base Debian Cloud image not found. Downloading..."
    wget -O "${STORAGE_PATH}/${BASE_IMAGE_NAME}" "$BASE_IMAGE_URL"
    log "SUCCESS" "Base image downloaded."
fi

# --- Disk Creation Logic ---
log "INFO" "💿 Creating VM disk image..."
if [ "${VM_TYPE}" == "disposable" ]; then
    # Create a non-persistent disk (backing file) that resets on every boot.
    qemu-img create -f qcow2 -b "${STORAGE_PATH}/${BASE_IMAGE_NAME}" "$VM_DISK_PATH"
    log "SUCCESS" "Created non-persistent disk for disposable VM."
else
    # Create a persistent disk by copying the base image and resizing it.
    cp "${STORAGE_PATH}/${BASE_IMAGE_NAME}" "$VM_DISK_PATH"
    qemu-img resize "$VM_DISK_PATH" "$DISK_SIZE"
    log "SUCCESS" "Created persistent disk with size ${DISK_SIZE}."
fi

# --- Image Customization (virt-customize) ---
log "INFO" "🔧 Customizing image (setting password, resizing FS, running setup scripts)..."
# Build the virt-customize command dynamically
VIRT_CUSTOMIZE_CMD="virt-customize -a \"$VM_DISK_PATH\" --root-password password:changeme --run-command 'growpart /dev/sda 1 && resize2fs /dev/sda1'"

# Check if a special setup script is defined in the profile (e.g., for the Tor VM)
if [ -n "${SETUP_SCRIPT_PATH:-}" ] && [ -f "$CHIMERA_ROOT/$SETUP_SCRIPT_PATH" ]; then
    UPLOAD_TARGET="/root/$(basename "$SETUP_SCRIPT_PATH")"
    VIRT_CUSTOMIZE_CMD+=" --upload \"$CHIMERA_ROOT/$SETUP_SCRIPT_PATH\":\"$UPLOAD_TARGET\""
    VIRT_CUSTOMIZE_CMD+=" --run-command 'chmod +x $UPLOAD_TARGET'"
    VIRT_CUSTOMIZE_CMD+=" --run-command '$UPLOAD_TARGET'"
    VIRT_CUSTOMIZE_CMD+=" --run-command 'rm $UPLOAD_TARGET'"
    log "INFO" "  - Will upload and execute special setup script: $(basename "$SETUP_SCRIPT_PATH")"
elif [ -n "${SETUP_SCRIPT_PATH:-}" ]; then
     log "WARN" "Setup script specified but not found: $CHIMERA_ROOT/$SETUP_SCRIPT_PATH"
fi

# Execute the final command
eval "$VIRT_CUSTOMIZE_CMD"

# --- VM Creation (virt-install) ---
log "INFO" "⚙️  Defining and creating the VM with libvirt..."
virt-install --name "$VM_NAME" \
    --ram "$VM_RAM" \
    --vcpus "$VM_VCPUS" \
    --os-variant debian12 \
    --disk path="$VM_DISK_PATH",device=disk,bus=virtio \
    --import \
    --graphics spice,listen=none --noautoconsole \
    --network network=default,model=virtio \
    --metadata description="Chimera Guardian VM - Profile: ${PROFILE_NAME}"

echo ""
log "SUCCESS" "✅ VM '${VM_NAME}' created successfully!"
log "WARN" "Default root password is: changeme (CHANGE THIS ON FIRST LOGIN)"

if [ "${VM_TYPE}" == "disposable" ]; then
    log "WARN" "‼️  This is a disposable VM. All changes will be lost on shutdown."
else
    log "INFO" "  - This is a persistent VM. Changes will be saved."
fi

# Provide specific instructions for Tor VM
if [ "${PROFILE_NAME}" == "tor" ]; then
    log "WARN" "‼️  ACTION REQUIRED for Tor VM:"
    log "WARN" "1. Start the VM from 'Virtual Machine Manager'."
    log "WARN" "2. Open the console and log in as 'root' (password: changeme)."
    log "WARN" "3. Run the command: ./setup-desktop.sh"
    log "WARN" "4. Follow the prompts to create your user and reboot."
fi

log "INFO" "You can now manage this VM using the 'Virtual Machine Manager' (vms command)."