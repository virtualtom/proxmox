# Proxmox: Cloning VMs that Auto-Start a Docker App (Example: Uptime Kuma)

This guide shows how to feed a working `docker-compose.yml` into your Proxmox clone workflow so the app starts on first boot. It uses your **known-good clone script** (`clone_from_deb12_docker_base.sh`) and adds two small helpers:

- `make_user_data_from_compose.sh` – converts any compose file to a cloud-init user-data snippet for a specific VM
- `compose_clone.sh` – convenience wrapper that combines: generate snippet → clone VM → bind snippet

> Your base template (VMID **9000**) is Debian 12 with Docker and QEMU guest agent already present.

---

## Example App: Uptime Kuma

A simple, popular uptime monitor with a web UI at **http://\<VM-IP\>:3001**.

**`docker-compose.yml`**
```yaml
version: "3.8"

services:
  uptime-kuma:
    image: louislam/uptime-kuma:1
    container_name: uptime-kuma
    restart: unless-stopped
    ports:
      - "3001:3001"
    volumes:
      - /opt/uptime-kuma/data:/app/data
    environment:
      # Adjust timezone as needed
      - TZ=America/New_York
```

Place this file somewhere on your Proxmox node (e.g. `/mnt/pve/pve-qnap/apps/kuma/docker-compose.yml`) **or** keep it local in `/root` if you prefer.

---

## Install the helpers (once)

Copy the three files from the bundle to your Proxmox node:

- `docker-compose.yml` (example above; use your real app compose)
- `make_user_data_from_compose.sh` → `/usr/local/sbin/make_user_data_from_compose.sh` (or keep in `/root`)
- `compose_clone.sh` → `/usr/local/sbin/compose_clone.sh` (or `/root`)

Then:
```bash
chmod +x /usr/local/sbin/make_user_data_from_compose.sh /usr/local/sbin/compose_clone.sh
```

> Assumes your working clone script lives at `/root/clone_from_deb12_docker_base.sh` and uses template **9000**.

---

## Fast path (one command)

```bash
compose_clone.sh 950 kuma-01 ~/.ssh/id_ed25519.pub 'StrongPassw0rd!' /mnt/pve/pve-qnap/apps/kuma/docker-compose.yml
```

What this does:
1. Creates `/var/lib/vz/snippets/kuma-01.yaml` from your compose.
2. Clones 9000 → **VMID 950**, name **kuma-01**, injects your SSH key + password (console + SSH login will work just like your known-good flow).
3. Binds the per-VM user-data and updates cloud-init so Docker brings the app up on first boot.

Open: `http://<VM-IP>:3001`

---

## Manual steps (if you don’t use the wrapper)

1) Build per-VM user-data from a compose file:
```bash
make_user_data_from_compose.sh kuma-02 /path/to/docker-compose.yml
# -> creates /var/lib/vz/snippets/kuma-02.yaml
```

2) Clone using your working script:
```bash
/root/clone_from_deb12_docker_base.sh 951 kuma-02 ~/.ssh/id_ed25519.pub 'StrongPassw0rd!'
```

3) Bind user-data and update cloud-init:
```bash
qm set 951 --cicustom "user=local:snippets/kuma-02.yaml"
qm cloudinit update 951
# If needed: qm start 951
```

---

## Why this keeps login working

We **don’t** use `users:` or `ssh_pwauth:` inside cloud-init user-data (which can override Proxmox `qm set` auth). All login settings come from:
```
qm set <vmid> --ciuser dockeruser --cipassword '...' --sshkey ~/.ssh/id_ed25519.pub
```
This is the method you confirmed works reliably.

---

## Tips

- **Disk resize**: You can still pass a size to your working clone script (before first boot) so the filesystem autogrows.
- **.env files / secrets**: Add another `write_files` block in the snippet, or mount from NFS and reference absolute paths in your compose.
- **Idempotent**: Re-running the same compose is fine; Docker will reconcile.
- **Logs**: `journalctl -u docker -e` and `docker ps -a` are good first checks.
