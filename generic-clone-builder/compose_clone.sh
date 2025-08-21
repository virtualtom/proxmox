#!/usr/bin/env bash
# compose_clone.sh
# Wrapper that:
#  1) Generates per-VM user-data from a docker-compose.yml
#  2) Clones from your working Docker-ready template using clone_from_deb12_docker_base.sh
#  3) Binds the user-data to the VM and updates cloud-init
#
# Usage:
#   compose_clone.sh <vmid> <name> <pubkey_path> <password> <compose_path>
#
# Example:
#   compose_clone.sh 950 kuma-01 ~/.ssh/id_ed25519.pub 'StrongPassw0rd!' /mnt/pve/pve-qnap/apps/kuma/docker-compose.yml
#
# Requirements:
#   - /root/clone_from_deb12_docker_base.sh exists (your working script)
#   - make_user_data_from_compose.sh is installed (this repo file)
#   - Template 9000 is your Debian 12 + Docker base template

set -euo pipefail

NEWID=${1:?Usage: $0 <vmid> <name> <pubkey> <password> <compose_path>}
NEWNAME=${2:?Usage: $0 <vmid> <name> <pubkey> <password> <compose_path>}
PUBKEY=${3:?Usage: $0 <vmid> <name> <pubkey> <password> <compose_path>}
CIPASS=${4:?Usage: $0 <vmid> <name> <pubkey> <password> <compose_path>}
COMPOSE_PATH=${5:?Usage: $0 <vmid> <name> <pubkey> <password> <compose_path>}

SNIP="/var/lib/vz/snippets/${NEWNAME}.yaml"

# 1) Build user-data for this VM
make_user_data_from_compose.sh "$NEWNAME" "$COMPOSE_PATH"

# 2) Clone using your *working* script
/root/clone_from_deb12_docker_base.sh "$NEWID" "$NEWNAME" "$PUBKEY" "$CIPASS"

# 3) Bind the user-data and update cloud-init
qm set "$NEWID" --cicustom "user=local:snippets/${NEWNAME}.yaml"
qm cloudinit update "$NEWID"

echo "[✓] Clone ${NEWID} (${NEWNAME}) created and compose applied. Container(s) should start on first boot."
