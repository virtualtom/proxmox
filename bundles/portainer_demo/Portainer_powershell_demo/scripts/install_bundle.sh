#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SNIP_SRC="$SRC_DIR/snippets"
SCR_SRC="$SRC_DIR/scripts"

SNIP_DST="/var/lib/vz/snippets"
mkdir -p "$SNIP_DST"

echo "[*] Removing old snippets and scripts..."
rm -f "$SNIP_DST"/portainer*.yaml || true
rm -f "$SNIP_DST"/powershell*.yaml || true
rm -f /root/clone_portainer.sh /root/clone_powershell.sh || true

echo "[*] Installing new snippets..."
cp "$SNIP_SRC/portainer-vendor.yaml" "$SNIP_DST/"
cp "$SNIP_SRC/powershell-vendor.yaml" "$SNIP_DST/"

echo "[*] Installing clone scripts..."
cp "$SCR_SRC/clone_portainer.sh" /root/
cp "$SCR_SRC/clone_powershell.sh" /root/
chmod +x /root/clone_portainer.sh /root/clone_powershell.sh

echo "[✓] Installed. Use:"
echo "  /root/clone_portainer.sh <vmid> <name> <pubkey> <PasswordOr->"
echo "  /root/clone_powershell.sh <vmid> <name> <pubkey> <PasswordOr->"
