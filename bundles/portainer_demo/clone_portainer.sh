#!/usr/bin/env bash
# clone_portainer.sh: Clone from Docker-ready template and auto-bootstrap Portainer via cloud-init.
# Usage: ./clone_portainer.sh <new_vmid> <name> <pubkey_path> [password|-]
set -euo pipefail

TEMPLATE_VMID=${TEMPLATE_VMID:-9000}
SNIPPETS_DIR=${SNIPPETS_DIR:-/var/lib/vz/snippets}
USERDATA_FILE=${USERDATA_FILE:-portainer-userdata.yaml}
CIUSER=${CIUSER:-dockeruser}

NEWID=${1:?Usage: $0 <new_vmid> <name> <pubkey_path> [password|-]}
NEWNAME=${2:?}
PUBKEY=${3:?}
CIPASS=${4:-"BetterPassw0rd!"}

[[ -f "$PUBKEY" ]] || { echo "Public key not found: $PUBKEY"; exit 1; }
[[ -f "$SNIPPETS_DIR/$USERDATA_FILE" ]] || { echo "User-data snippet not found: $SNIPPETS_DIR/$USERDATA_FILE"; exit 1; }

echo "[*] Cloning template $TEMPLATE_VMID -> $NEWID ($NEWNAME)..."
qm clone "$TEMPLATE_VMID" "$NEWID" --name "$NEWNAME" --full

# Optional: resize disk BEFORE first boot (uncomment to use)
# qm resize "$NEWID" scsi0 30G

echo "[*] Configuring cloud-init (user, password/keys, DHCP, user-data)..."
if [[ "$CIPASS" != "-" ]]; then
  qm set "$NEWID" --ciuser "$CIUSER" --cipassword "$CIPASS"
else
  qm set "$NEWID" --ciuser "$CIUSER"
fi
qm set "$NEWID" --sshkey "$PUBKEY"
qm set "$NEWID" --ipconfig0 ip=dhcp
qm set "$NEWID" --cicustom "user=local:snippets/${USERDATA_FILE}"
qm cloudinit update "$NEWID"

echo "[*] Starting VM..."
qm start "$NEWID"

cat <<'EOS'

[✓] VM started. On first boot, cloud-init writes /opt/portainer/docker-compose.yml,
creates a systemd unit, and runs "docker compose up -d".

Next steps:
  1) Get the VM IP from the Proxmox GUI (Summary tab) once the QEMU agent reports it.
  2) Open https://<VM-IP>:9443 in your browser (Portainer CE).
  3) Create the initial admin user in the Portainer UI.

Troubleshooting:
  - Check service logs:   sudo journalctl -u compose-portainer -n 200 --no-pager
  - Check Docker status:  docker ps
  - If cloud-init didn't run: sudo cloud-init status --long
EOS
