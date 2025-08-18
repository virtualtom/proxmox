#!/usr/bin/env bash
# prep_guest_deb12.sh
# Inside the Debian 12 VM: enable serial login, install qemu-guest-agent and Docker.

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo "[*] Ensuring serial login (getty on ttyS0) while keeping VGA available..."
# Enable agetty on serial0
systemctl enable serial-getty@ttyS0.service
systemctl start  serial-getty@ttyS0.service

echo "[*] System update + prerequisites..."
apt-get update

echo "[*] Installing QEMU guest agent..."
apt-get install -y qemu-guest-agent
# Start agent (service may be socket-activated; both are fine)
systemctl start qemu-guest-agent || true
# Enable the socket unit (clean enable path on Debian)
systemctl enable --now qemu-guest-agent.socket || true

echo "[*] Verifying agent device..."
ls -l /dev/virtio-ports/ || true

echo "[*] Installing Docker CE (official repo) + compose plugin..."
apt-get install -y ca-certificates curl gnupg lsb-release
mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/debian $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "[*] Enabling Docker and adding dockeruser to group..."
systemctl enable --now docker
usermod -aG docker dockeruser || true

echo "[*] (Optional) quick Docker sanity check..."
docker --version || true

echo "[✓] Guest prep complete. You can shut down and convert to template."
