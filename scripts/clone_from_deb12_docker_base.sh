#!/usr/bin/env bash
# clone_from_template.sh
# Clone from a Docker-ready Debian 12 template. Inject per-VM creds.
# Optionally resize disk and (if needed) show post-clone FS growth steps.

set -euo pipefail

# --- Defaults ---
TEMPLATE_VMID=${TEMPLATE_VMID:-9000}
NEWID=${1:?Usage: $0 <new_vmid> <new_name> <pubkey_path> [PasswordOr-] [SizeOr-]}
NEWNAME=${2:?Usage: $0 <new_vmid> <new_name> <pubkey_path> [PasswordOr-] [SizeOr-]}
PUBKEY=${3:?Usage: $0 <new_vmid> <new_name> <pubkey_path> [PasswordOr-] [SizeOr-]}
CIPASS=${4:-BetterPassw0rd!}   # pass '-' to skip setting a password
NEWDISK=${5:-}                 # e.g. 40G; pass '-' or empty to skip
CIUSER=${CIUSER:-dockeruser}
# -----------------

if [[ ! -f "$PUBKEY" ]]; then
  echo "ERROR: public key not found: $PUBKEY"; exit 1
fi

echo "[*] Cloning template $TEMPLATE_VMID -> $NEWID ($NEWNAME)..."
qm clone "$TEMPLATE_VMID" "$NEWID" --name "$NEWNAME" --full

# (Optional) resize disk BEFORE first boot (cloud-init may autogrow if first boot)
if [[ -n "${NEWDISK}" && "${NEWDISK}" != "-" ]]; then
  echo "[*] Resizing disk to $NEWDISK..."
  qm resize "$NEWID" scsi0 "$NEWDISK" || true
fi

echo "[*] Setting per-VM cloud-init credentials..."
if [[ "${CIPASS}" != "-" ]]; then
  qm set "$NEWID" --ciuser "$CIUSER" --cipassword "$CIPASS"
else
  qm set "$NEWID" --ciuser "$CIUSER"
fi
qm set "$NEWID" --sshkey "$PUBKEY"
qm cloudinit update "$NEWID"

echo "[*] Starting VM..."
qm start "$NEWID"

cat <<'EOS'

[✓] Clone started. Notes:

- If you resized AFTER the template already had a first boot, or if the root FS didn't grow:
  Inside the guest (Debian default ext4), run:
    sudo apt-get update && sudo apt-get install -y cloud-guest-utils
    lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT
    # Assume /dev/sda1 is root (virtio-scsi often shows as sda):
    sudo growpart /dev/sda 1
    sudo resize2fs /dev/sda1
  Then:
    df -h

- If you need to "reset" cloud-init state in a running clone (rare):
    sudo cloud-init clean
    sudo rm -rf /var/lib/cloud
    # Make sure you updated cloud-init settings on host first:
    #   qm set <vmid> --ciuser ... --cipassword ... --sshkey ...
    #   qm cloudinit update <vmid>
    sudo reboot

- QEMU Guest Agent:
  The template already has the agent package; ensure VM "Options -> QEMU Guest Agent = Enabled".
  You should see the IP on the Summary page shortly after boot.

EOS
