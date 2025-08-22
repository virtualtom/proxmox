#!/usr/bin/env bash
# make_user_data_from_compose.sh
# Usage: make_user_data_from_compose.sh <vm-name> <compose_path_on_host>
# Writes /var/lib/vz/snippets/<vm-name>.yaml suitable for Proxmox --cicustom

set -euo pipefail

VMNAME=${1:?Usage: $0 <vm-name> <compose-path>}
COMPOSE_SRC=${2:?Usage: $0 <vm-name> <compose-path>}

SNIP_DIR=/var/lib/vz/snippets
OUT="${SNIP_DIR}/${VMNAME}.yaml"

[[ -f "$COMPOSE_SRC" ]] || { echo "Compose file not found: $COMPOSE_SRC"; exit 1; }
mkdir -p "$SNIP_DIR"

# indent compose file by 6 spaces for YAML literal block under write_files->content
INDENTED=$(sed 's/^/      /' "$COMPOSE_SRC")

cat > "$OUT" <<EOF
#cloud-config
write_files:
  - path: /opt/app/docker-compose.yml
    permissions: '0644'
    content: |
${INDENTED}

runcmd:
  - 'command -v docker >/dev/null || (apt-get update && apt-get install -y docker.io qemu-guest-agent)'
  - systemctl enable --now docker
  - docker compose -f /opt/app/docker-compose.yml up -d
EOF

echo "[*] Wrote user-data: $OUT"
