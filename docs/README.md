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
