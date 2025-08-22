# Docker Template: Debian 12 + Docker + QEMU Guest Agent

This guide builds a Debian 12 (Bookworm) Docker-ready VM, then converts it to a Proxmox template.

## Prereqs
- Proxmox VE host with a storage (example: `local-lvm`)
- Network bridge (example: `vmbr0`)
- SSH public key on the host (example: `/root/.ssh/id_ed25519.pub`)

## 1) Download the Debian cloud image (qcow2) on the Proxmox node
```bash
cd /var/lib/vz/template
mkdir -p images && cd images
wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2
```

## 2) Create the VM and import the disk
```bash
VMID=9000
NAME=deb12-docker-base
STORAGE=local-lvm
BRIDGE=vmbr0

qm create "$VMID" --name "$NAME" --memory 2048 --cores 2 --net0 virtio,bridge="$BRIDGE"
qm importdisk "$VMID" debian-12-genericcloud-amd64.qcow2 "$STORAGE"
qm set "$VMID" --scsihw virtio-scsi-pci --scsi0 "$STORAGE:vm-$VMID-disk-0"
qm set "$VMID" --ide2 "$STORAGE:cloudinit"
qm set "$VMID" --boot c --bootdisk scsi0
qm set "$VMID" --serial0 socket --vga serial0
qm set "$VMID" --agent enabled=1
qm set "$VMID" --sshkeys /root/.ssh/id_ed25519.pub
```

## 3) First boot: install qemu-guest-agent, Docker and compose
Start the VM, log in (default cloud user is `debian` unless you changed it), then run:
```bash
sudo -i
apt-get update
apt-get install -y qemu-guest-agent ca-certificates curl gnupg
systemctl enable --now qemu-guest-agent
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo $VERSION_CODENAME) stable" > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker
docker version
docker compose version
poweroff
```

## 4) Convert to a Proxmox template
```bash
qm template "$VMID"
```

## 5) Clone example (manual)
```bash
NEWID=950
NAME=kuma-01
STORAGE=local-lvm
qm clone "$VMID" "$NEWID" --name "$NAME" --full 1 --storage "$STORAGE"
qm set "$NEWID" --sshkeys /root/.ssh/id_ed25519.pub
qm start "$NEWID"
```

Tips:
- If you prefer to install Docker on first boot, you can attach a cloud-init snippet that runs the install commands via `runcmd`. The above method bakes Docker into the template.
