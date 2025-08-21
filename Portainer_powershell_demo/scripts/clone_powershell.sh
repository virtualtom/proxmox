#!/usr/bin/env bash
set -euo pipefail

TEMPLATE_VMID=${TEMPLATE_VMID:-9000}
NEWID=${1:?Usage: $0 <new_vmid> <new_name> <pubkey_path> [PasswordOr-]}
NEWNAME=${2:?Usage: $0 <new_vmid> <new_name> <pubkey_path> [PasswordOr-]}
PUBKEY=${3:?Usage: $0 <new_vmid> <new_name> <pubkey_path> [PasswordOr-]}
CIPASS=${4:-BetterPassw0rd!}
CIUSER=${CIUSER:-dockeruser}

if [[ ! -f "$PUBKEY" ]]; then
  echo "ERROR: public key not found: $PUBKEY"; exit 1
fi

echo "[*] Cloning template $TEMPLATE_VMID -> $NEWID ($NEWNAME)..."
qm clone "$TEMPLATE_VMID" "$NEWID" --name "$NEWNAME" --full

echo "[*] Injecting creds (ciuser/cipassword/sshkey) and DHCP..."
if [[ "${CIPASS}" != "-" ]]; then
  qm set "$NEWID" --ciuser "$CIUSER" --cipassword "$CIPASS"
else
  qm set "$NEWID" --ciuser "$CIUSER"
fi
qm set "$NEWID" --sshkey "$PUBKEY"
qm set "$NEWID" --ipconfig0 ip=dhcp

echo "[*] Binding vendor-data snippet (keeps Proxmox user-data intact)..."
qm set "$NEWID" --cicustom "vendor=local:snippets/powershell-vendor.yaml"

echo "[*] Update cloud-init ISO and start..."
qm cloudinit update "$NEWID"
qm start "$NEWID"

echo "[✓] PowerShell clone started. 'pwsh' container will be running."
