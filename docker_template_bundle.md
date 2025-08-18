# Proxmox Docker Template with Cloud-Init & Compose

This bundle includes:

- `snippets/app-inline-userdata.yaml`: cloud-init snippet with inline docker-compose
- `snippets/app-fetch-userdata.yaml`: cloud-init snippet that fetches docker-compose from URL
- `provision_compose_clone.sh`: helper script to clone from template and inject compose

## Usage

1. Copy `snippets/*.yaml` to your Proxmox snippets storage (e.g. `/var/lib/vz/snippets`).
2. Copy `provision_compose_clone.sh` to your Proxmox host and `chmod +x` it.
3. Run:

```bash
./provision_compose_clone.sh 201 web01 ~/.ssh/id_ed25519.pub myweb https://example.com/docker-compose.yml
```

The VM will boot, fetch or write the compose file, and auto-start it as a systemd service.
