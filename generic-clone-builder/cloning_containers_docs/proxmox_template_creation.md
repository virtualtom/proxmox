# Proxmox: Creating a Debian 12 Docker-Ready Template (VMID 9000)

## Steps

1. Download Debian 12 cloud image:
```bash
wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2
```

2. Create VM shell in Proxmox:
```bash
qm create 9000 --name debian12-docker --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-pci --scsi0 local-lvm:0,discard=on
```

3. Import disk:
```bash
qm importdisk 9000 debian-12-genericcloud-amd64.qcow2 local-lvm
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
```

4. Enable cloud-init drive:
```bash
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
```

5. Install Docker + QEMU guest agent (first boot):
```bash
apt-get update
apt-get install -y docker.io qemu-guest-agent cloud-init
systemctl enable qemu-guest-agent docker
```

6. Shut down and convert to template:
```bash
qm shutdown 9000
qm template 9000
```

## Result
VMID 9000 is now a golden Debian 12 + Docker + Cloud-init + QGA template.
