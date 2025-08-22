# Generic Clone Builder (Compose)

Two supported ways to bring up containers from an existing `docker-compose.yml` when cloning from the Docker-ready template.

## A) Snippet-based (cloud-init user-data)

Use the helper script already in the repo to generate a cloud-init user-data snippet from your compose file.

Script:
```
bundles/generic-clone-builder/make_user_data.sh
```

Usage:
```bash
bundles/generic-clone-builder/make_user_data.sh <COMPOSE_YML> <SNIPPET_NAME.yaml>
```

Example:
```bash
sudo bundles/generic-clone-builder/make_user_data.sh /mnt/pve/pve-qnap/apps/kuma/docker-compose.yml compose-kuma.yaml
```

Result:
- Creates `/var/lib/vz/snippets/compose-kuma.yaml`
- On first boot, cloud-init writes the compose file to `/opt/compose/docker-compose.yml` and runs `docker compose up -d`

Clone and attach the snippet:
```bash
TEMPLATE_ID=9000
NEWID=950
NAME=kuma-01
STORAGE=local-lvm
qm clone "$TEMPLATE_ID" "$NEWID" --name "$NAME" --full 1 --storage "$STORAGE"
qm set "$NEWID" --sshkeys /root/.ssh/id_ed25519.pub
qm set "$NEWID" --cicustom "user=local:snippets/compose-kuma.yaml"
qm start "$NEWID"
```

## B) Script-based (copy compose and start)

Use the helper that copies a compose file into the VM and starts it on first boot.

Script:
```
bundles/generic-clone-builder/compose_clone.sh
```

Usage:
```bash
./bundles/generic-clone-builder/compose_clone.sh <VMID> <NAME> <PUBKEY_PATH> <COMPOSE_YML>
```

Example:
```bash
./bundles/generic-clone-builder/compose_clone.sh 950 kuma-01 ~/.ssh/id_ed25519.pub /mnt/pve/pve-qnap/apps/kuma/docker-compose.yml
```

## Requirements
- Base template has Docker and the compose plugin installed
- The compose file path is readable from the Proxmox node
- SSH public key path exists on the node

## Troubleshooting
- If containers did not start, SSH into the VM and run:
```bash
docker compose -f /opt/compose/docker-compose.yml up -d
```
- Check cloud-init status in the VM:
```bash
sudo cloud-init status --long
```
