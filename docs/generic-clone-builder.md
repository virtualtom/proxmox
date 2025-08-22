# Generic Clone Builder (Compose)

Use an existing `docker-compose.yml` to clone from the Docker template and start your stack on first boot.

## Requirements
- A Docker-ready Debian 12 template (see the Docker Template guide)
- The compose file is readable from the Proxmox host (for example: `/mnt/pve/pve-qnap/apps/kuma/docker-compose.yml`)
- Your SSH public key path on the host

## Script
`bundles/generic-clone-builder/compose_clone.sh`

## Usage
```bash
./bundles/generic-clone-builder/compose_clone.sh <VMID> <NAME> <PUBKEY_PATH> <COMPOSE_YML>
```

Example:
```bash
./bundles/generic-clone-builder/compose_clone.sh 950 kuma-01 ~/.ssh/id_ed25519.pub /mnt/pve/pve-qnap/apps/kuma/docker-compose.yml
```

## What happens
1. Clones the Docker-base template into a new VM with the given VMID and NAME
2. Injects your SSH public key via cloud-init
3. Copies the `docker-compose.yml` into the VM (default path: `/opt/compose/docker-compose.yml`)
4. On first boot, brings the stack up with `docker compose up -d`

## First-boot behavior
The template already includes Docker and the compose plugin. On first boot the VM runs:
```bash
docker compose -f /opt/compose/docker-compose.yml pull
docker compose -f /opt/compose/docker-compose.yml up -d
```

## Troubleshooting
- If containers did not start: `ssh` into the VM and run:
```bash
docker compose -f /opt/compose/docker-compose.yml up -d
```
- Ensure the `COMPOSE_YML` path on the Proxmox host is accessible to the user invoking `qm`
- Verify the template has Docker and `docker compose` installed
