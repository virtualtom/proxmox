# Proxmox Clone Bundle (Vendor-data only)

**Fix for login issues:** We now use **vendor-data** snippets so Proxmox’s generated **user-data** (which carries `ciuser`, `cipassword`, `sshkey`, and the hostname) remains intact. That is why console and SSH public-key login work in your “good” script, and it’s exactly what these scripts replicate.

## Install

```bash
cd /root
tar xzf proxmox-fixed-bundle.tar.gz
cd proxmox-fixed-bundle/scripts
chmod +x install_bundle.sh
./install_bundle.sh
```

## Use

```bash
# Portainer
/root/clone_portainer.sh 910 portainer-01 ~/.ssh/id_ed25519.pub 'BetterPassw0rd!'

# PowerShell
/root/clone_powershell.sh 920 ps-host-01 ~/.ssh/id_ed25519.pub 'BetterPassw0rd!'
```

- Hostname: preserved from Proxmox generated user-data (matches the VM name).
- Login: `dockeruser` with the password you passed, plus your SSH public key.
- Portainer UI: `https://<VM-IP>:9443`
- PowerShell container name: `pwsh`
