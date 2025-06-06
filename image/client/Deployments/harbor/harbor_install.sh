#!/bin/bash
set -e

HARBOR_DIR="/opt/harbor"
CERT_DIR="/etc/harbor/ssl"
DOMAIN="harbor.local"
PASSWORD_ADMIN="SuperSecretPass123"
DATA_VOLUME="/data"

# Install dependencies
dnf install -y docker docker-compose openssl

# Enable and start Docker
systemctl enable --now docker

# Create cert directory
mkdir -p "$CERT_DIR"

# Generate self-signed cert
openssl req -x509 -nodes -days 365 -newkey rsa:4096 \
  -keyout "$CERT_DIR/harbor.key" \
  -out "$CERT_DIR/harbor.crt" \
  -subj "/CN=$DOMAIN"

# Download Harbor
curl -L https://github.com/goharbor/harbor/releases/download/v2.13.1/harbor-offline-installer-v2.13.1.tgz -o /tmp/harbor.tgz
mkdir -p "$HARBOR_DIR"
tar -xzf /tmp/harbor.tgz -C "$HARBOR_DIR" --strip-components=1

# Generate harbor.yml
cat > "$HARBOR_DIR/harbor.yml" <<EOF
hostname: $DOMAIN
https:
  port: 443
  certificate: $CERT_DIR/harbor.crt
  private_key: $CERT_DIR/harbor.key
harbor_admin_password: $PASSWORD_ADMIN
database:
  password: HarborDBPass!
data_volume: $DATA_VOLUME
jobservice:
  max_job_workers: 10
  max_job_duration_hours: 24
  job_loggers:
    - STD_OUTPUT
    - file
  logger_sweeper_duration: 1
notification:
  webhook_job_max_retry: 3
  webhook_job_http_client_timeout: 300
log:
  level: info
  local:
    log_location: /var/log/harbor
    rotate_count: 5
trivy:
  ignoreUnfixed: false
  insecure: true
  skipUpdate: false
  offlineScan: true
  vulnType: "os,library"
  severity: "CRITICAL,HIGH"
EOF

# Run installer
cd "$HARBOR_DIR"
./install.sh

# Output containerd snippet
echo -e "\nAdd this to your containerd config:"
cat <<CONTAINERD
[plugins."io.containerd.grpc.v1.cri".registry.mirrors."$DOMAIN"]
  endpoint = ["https://$DOMAIN"]

[plugins."io.containerd.grpc.v1.cri".registry.configs."$DOMAIN".tls]
  insecure_skip_verify = true
CONTAINERD
