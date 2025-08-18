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

## Full Files

### snippets/app-inline-userdata.yaml

```yaml
#cloud-config
package_update: true
package_upgrade: true
packages:
  - docker.io
  - docker-compose
runcmd:
  - [ sh, -c, "docker compose -f /opt/app/docker-compose.yml up -d" ]
write_files:
  - path: /opt/app/docker-compose.yml
    permissions: '0644'
    content: |
      version: '3'
      services:
        hello:
          image: hello-world

```

### snippets/app-fetch-userdata.yaml

```yaml
#cloud-config
package_update: true
package_upgrade: true
packages:
  - docker.io
  - docker-compose
runcmd:
  - [ sh, -c, "curl -fsSL https://example.com/docker-compose.yml -o /opt/app/docker-compose.yml" ]
  - [ sh, -c, "docker compose -f /opt/app/docker-compose.yml up -d" ]

```

### provision_compose_clone.sh

```bash
#!/bin/bash
# provision_compose_clone.sh <NEWID> <NEWHOSTNAME> <PUBKEYFILE> <APPNAME> <COMPOSE_URL>
set -e

TEMPLATE_ID=9000
NEWID=$1
NEWHOSTNAME=$2
PUBKEYFILE=$3
APPNAME=$4
COMPOSE_URL=$5

qm clone $TEMPLATE_ID $NEWID --name $NEWHOSTNAME
qm set $NEWID --ciuser dockeruser --sshkey $PUBKEYFILE
qm set $NEWID --ipconfig0 ip=dhcp
qm set $NEWID --cicustom "user=local:snippets/app-fetch-userdata.yaml"
qm start $NEWID

```
