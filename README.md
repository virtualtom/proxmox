# Proxmox Templates & Bundles

[![Docs](https://img.shields.io/badge/docs-GitHub%20Pages-blue)](https://virtualtom.github.io/proxmox/)

Automation and docs for building and cloning **Debian 12 Docker-ready VM templates** on Proxmox VE, plus example bundles like a **Portainer demo** and a **generic clone builder** that uses an existing `docker-compose.yml`.

## What’s here
- **Docker Template (Debian 12 + Docker)**: prepare, build, and clone scripts
- **Generic Clone Builder**: clone from the template and bring up a given `docker-compose.yml`
- **Portainer Demo**: cloud-init userdata + helper script

## Quickstart
```bash
bash scripts/prep_deb12_docker_base.sh
bash scripts/build_deb12_docker_base.sh
bash scripts/clone_from_deb12_docker_base.sh <VMID> <NAME> <PUBKEY_PATH> <COMPOSE_YML>
```

Generic clone builder:
```bash
./bundles/generic-clone-builder/compose_clone.sh <VMID> <NAME> <PUBKEY_PATH> <COMPOSE_YML>
# example:
./bundles/generic-clone-builder/compose_clone.sh 950 kuma-01 ~/.ssh/id_ed25519.pub /mnt/pve/pve-qnap/apps/kuma/docker-compose.yml
```

## Docs
Full documentation: https://virtualtom.github.io/proxmox/

Key pages:
- Docker Template: https://virtualtom.github.io/proxmox/docker-template/
- Portainer Demo: https://virtualtom.github.io/proxmox/portainer-demo/
- Generic Clone Builder: https://virtualtom.github.io/proxmox/generic-clone-builder/

## Repo layout
```
docs/
  index.md
  overview.md
  docker-template.md
  portainer-demo.md
  generic-clone-builder.md
scripts/
bundles/
  portainer_demo/
templates/
.github/workflows/
```

## Contributing
- Open an issue or PR
- Checks: ShellCheck in CI; docs with `python3 -m mkdocs build`

## License
GPL-3.0 — see `LICENSE`.
