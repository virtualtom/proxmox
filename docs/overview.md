# Proxmox Templates & Bundles — Overview

This repository includes:
- **Docker base on Debian 12**: prepare, build, and clone scripts.
- **Portainer demo**: cloud-init snippet + helper script.

## Quickstart (Debian 12 Docker base)

```bash
bash scripts/prep_deb12_docker_base.sh
bash scripts/build_deb12_docker_base.sh
bash scripts/clone_from_deb12_docker_base.sh <VMID> <NAME> <PUBKEY_PATH> <compose.yml-path>
```

More: [docker-template.md](./docker-template.md) • [portainer-demo.md](./portainer-demo.md)
## Deploying to a Proxmox node

1. Place or mount this repo on the Proxmox host
2. Run the deploy script

3. Use the installed helpers and snippets:
- Scripts in /usr/lib/sbin (or your chosen --sbindir)
- Snippets in /var/lib/vz/snippets
