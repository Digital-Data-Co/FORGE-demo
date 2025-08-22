#!/bin/bash
set -e

RPM_DIR="./docker_rpms"
INSTALL_LOCAL=false

usage() {
  echo "Usage: $0 [--install-local]"
  echo "  --install-local    Install the RPMs locally (used on the airgapped machine)"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-local)
      INSTALL_LOCAL=true
      shift
      ;;
    *)
      usage
      ;;
  esac
done

mkdir -p "$RPM_DIR"
cd "$RPM_DIR"

if [ "$INSTALL_LOCAL" = false ]; then
  echo "[+] Downloading Docker and dependencies for RHEL 9..."
  sudo dnf install -y yum-utils
  sudo yumdownloader --resolve \
    docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

  echo "[+] RPMs downloaded to: $(pwd)"
  echo "[+] Transfer this directory to your airgapped system and re-run this script with --install-local"
else
  echo "[+] Installing Docker RPMs locally..."
  sudo dnf install -y ./*.rpm

  echo "[+] Enabling and starting Docker..."
  sudo systemctl enable --now docker

  echo "[+] Docker installation complete:"
  docker version || echo "Docker not responding. Check for errors."
fi
