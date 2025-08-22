# Generic Clone Builder (Compose)

Use an existing docker-compose.yml to clone a Debian 12 Docker VM template and bring up the container stack on first boot.

## Prereqs
- Proxmox template: Debian 12 with Docker, cloud-init enabled
- SSH public key path available on the Proxmox node
- Compose file accessible by the Proxmox node

## Script
bundles/generic-clone-builder/compose_clone.sh

## Usage
./bundles/generic-clone-builder/compose_clone.sh <VMID> <NAME> <PUBKEY_PATH> <COMPOSE_YML>

Example:
./bundles/generic-clone-builder/compose_clone.sh 950 kuma-01 ~/.ssh/id_ed25519.pub /mnt/pve/pve-qnap/apps/kuma/docker-compose.yml

## What it does
1. Clones the Docker-base template into a new VM with the given VMID and NAME
2. Injects your SSH public key via cloud-init
3. Copies the docker-compose.yml to the VM
4. Enables Docker and brings the stack up on first boot

## Inputs
VMID: integer unique per VM  
NAME: VM name  
PUBKEY_PATH: path to your id_ed25519.pub or id_rsa.pub on the Proxmox node  
COMPOSE_YML: full path to docker-compose.yml on Proxmox storage (e.g., NFS mount)

## Outputs
- New VM named NAME
- Stack started by first-boot steps in the template

## Troubleshooting
- If the VM boots without containers, ssh in and run:
  docker compose -f /opt/compose/docker-compose.yml up -d
- Ensure COMPOSE_YML path is readable by the Proxmox node user running qm
- Verify the template has Docker and the docker compose plugin installed
