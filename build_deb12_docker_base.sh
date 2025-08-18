#!/usr/bin/env bash
# build_deb12_docker_base.sh
# Creates a Debian 12 base VM (not a template yet) from a qcow2 in ISO dir,
# with both VGA (noVNC) and serial0, cloud-init, and agent device enabled.

set -euo pipefail

# --- Config (adjust as needed) ---
VMID=${VMID:-9000}
NAME=${NAME:-deb12-docker-base}
BRIDGE=${BRIDGE:-vmbr0}
MEM=${MEM:-2048}
CORES=${CORES:-2}
DISK_SIZE=${DISK_SIZE:-20G}
ISO_QCOW_PATH=${ISO_QCOW_PATH:-/var/lib/vz/template/iso/debian-12-genericcloud-amd64.qcow2}
STORAGE=${STORAGE:-local-lvm}
CIUSER=${CIUSER:-dockeruser}
CIPASS=${CIPASS:-TempPassw0rd!}   # just for first login; override per-clone later
# -------------------------------

if [[ ! -f "$ISO_QCOW_PATH" ]]; then
  echo "ERROR: qcow2 not found at $ISO_QCOW_PATH"; exit 1
fi

# Clean up any existing VMID
if qm status "$VMID" &>/dev/null; then
  echo "[*] Destroying existing VMID $VMID to start clean..."
  qm stop "$VMID" &>/dev/null || true
  sleep 2
  qm destroy "$VMID" --purge --destroy-unreferenced-disks 1
fi

echo "[*] Creating empty VM shell..."
qm create "$VMID" --name "$NAME" --ostype l26 --memory "$MEM" --cores "$CORES" \
  --net0 "virtio,bridge=$BRIDGE"

echo "[*] Importing qcow2 into $STORAGE..."
qm importdisk "$VMID" "$ISO_QCOW_PATH" "$STORAGE"

# Find the first unused disk reference (the volume we just imported)
DISK_REF=$(qm config "$VMID" | awk '/^unused[0-9]+: /{print $2; exit}')
if [[ -z "${DISK_REF:-}" ]]; then
  echo "ERROR: could not find imported disk in VM config"; exit 1
fi

echo "[*] Attaching imported disk as scsi0 and adding cloud-init..."
qm set "$VMID" --scsihw virtio-scsi-pci --scsi0 "$DISK_REF"
qm set "$VMID" --ide2 "${STORAGE}:cloudinit"

echo "[*] Setting boot order, VGA+serial, and enabling agent device..."
qm set "$VMID" --boot c --bootdisk scsi0
qm set "$VMID" --vga std
qm set "$VMID" --serial0 socket
qm set "$VMID" --agent enabled=1

echo "[*] Resizing disk to $DISK_SIZE (autogrow on first boot via cloud-init)..."
qm resize "$VMID" scsi0 "$DISK_SIZE" || true

echo "[*] Cloud-init basics (DHCP, temp password; NO SSH key baked in)..."
qm set "$VMID" --ciuser "$CIUSER" --cipassword "$CIPASS" --ipconfig0 ip=dhcp
qm cloudinit update "$VMID"

echo "[✓] Base VM $VMID ($NAME) is ready to boot."
echo "Next: start it, log in via noVNC or serial, then run the guest install script."
