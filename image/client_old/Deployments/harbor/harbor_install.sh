#!/bin/bash
set -euo pipefail

# ---- CONFIG ----
HARBOR_VERSION="v2.13.1"
HARBOR_HOST="harbor.local" # Hostname is required for certificate
HARBOR_INSTALL_DIR="/opt/harbor"
CERTS_DIR="${HARBOR_INSTALL_DIR}/cert"
HARBOR_ADMIN_PASS="SuperSecretPass123"
HARBOR_DB_PASS="HarborDBPass!"
USERS=("dnelson" "badamek")
USER_FULLNAMES=("Dave Nelson" "Brandon Adamek")
IMPORTED_IMAGES_DIR="/opt/harbor/imported"

# ---- PREP ----
echo "[1/9] Installing dependencies..."
dnf update -y
yum install -y docker.io docker-compose openssl curl jq

echo "[2/9] Downloading Harbor ${HARBOR_VERSION}..."
cd /tmp
curl -sLO "https://github.com/goharbor/harbor/releases/download/${HARBOR_VERSION}/harbor-offline-installer-${HARBOR_VERSION}.tgz"
tar xzf "harbor-offline-installer-${HARBOR_VERSION}.tgz" -C /opt/

echo "[3/9] Generating self-signed certs..."
mkdir -p "${CERTS_DIR}"
openssl req -x509 -nodes -days 365 -newkey rsa:4096 \
  -keyout "${CERTS_DIR}/harbor.key" \
  -out "${CERTS_DIR}/harbor.crt" \
  -subj "/CN=${HARBOR_HOST}"

# ---- CONFIG ----
echo "[4/9] Generating harbor.yml..."
cat > "${HARBOR_INSTALL_DIR}/harbor.yml" <<EOF
hostname: ${HARBOR_HOST}
https:
  port: 443
  certificate: ${CERTS_DIR}/harbor.crt
  private_key: ${CERTS_DIR}/harbor.key
harbor_admin_password: ${HARBOR_ADMIN_PASS}
database:
  password: ${HARBOR_DB_PASS}
data_volume: /data
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

echo "[5/9] Installing Harbor..."
cd "${HARBOR_INSTALL_DIR}"
./install.sh

echo "[6/9] Waiting for Harbor to start..."
sleep 10
docker-compose ps

# ---- USERS & PROJECTS ----
echo "[7/9] Creating users & project..."
HARBOR_API="https://${HARBOR_HOST}/api/v2.0"
AUTH="admin:${HARBOR_ADMIN_PASS}"

# Create 'k8s' project
curl -sk -u $AUTH -X POST "${HARBOR_API}/projects" \
  -H 'Content-Type: application/json' \
  -d '{"project_name":"k8s","metadata":{"public":"true"}}'

# Add users
for i in "${!USERS[@]}"; do
  USERNAME="${USERS[$i]}"
  REALNAME="${USER_FULLNAMES[$i]}"
  EMAIL="${EMAIL[$i]}"
  PASSWORD="$(openssl rand -base64 16)"
  echo "$USERNAME password: $PASSWORD"

  curl -sk -u $AUTH -X POST "${HARBOR_API}/users" \
    -H 'Content-Type: application/json' \
    -d "{\"username\":\"$USERNAME\",\"realname\":\"$REALNAME\",\"password\":\"$PASSWORD\",\"email\":\"$EMAIL\"}"

  curl -sk -u $AUTH -X POST "${HARBOR_API}/projects/k8s/members" \
    -H 'Content-Type: application/json' \
    -d "{\"role_id\":2,\"member_user\":{\"username\":\"$USERNAME\"}}"
done

# ---- IMAGE PRELOAD ----
echo "[8/9] Preloading Kubernetes & Calico images..."

IMAGES=(
  "registry.k8s.io/kube-apiserver:v1.32.5"
  "registry.k8s.io/kube-controller-manager:v1.32.5"
  "registry.k8s.io/kube-scheduler:v1.32.5"
  "registry.k8s.io/kube-proxy:v1.32.5"
  "registry.k8s.io/pause:3.10"
  "registry.k8s.io/etcd:3.5.21-0"
  "registry.k8s.io/coredns/coredns:v1.11.1"

  "docker.io/calico/cni:v3.30.1"
  "docker.io/calico/kube-controllers:v3.30.1"
  "docker.io/calico/node:v3.30.1"
  "docker.io/calico/typha:v3.30.1"
  "docker.io/calico/apiserver:v3.30.1"

  "docker.io/nicolaka/netshoot:latest"
)

ALL_IMAGES=("${K8S_IMAGES[@]}" "${CALICO_IMAGES[@]}")
for IMG in "${ALL_IMAGES[@]}"; do
  docker pull "$IMG"
  NAME=$(basename "$IMG")
  docker tag "$IMG" "${HARBOR_HOST}/k8s/$NAME"
  docker push "${HARBOR_HOST}/k8s/$NAME"
done

# ---- CUSTOM IMAGE IMPORT ----
echo "[9/9] Importing custom .tar.gz images..."
if [ -d "${IMPORTED_IMAGES_DIR}" ]; then
  for FILE in "${IMPORTED_IMAGES_DIR}"/*.tar.gz; do
    docker load -i "$FILE"
    IMAGE_ID=$(docker load -i "$FILE" | awk '/Loaded image:/ {print $3}')
    if [[ -n "$IMAGE_ID" ]]; then
      TAG=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep "$IMAGE_ID" | head -n1)
      docker tag "$TAG" "${HARBOR_HOST}/k8s/${TAG##*/}"
      docker push "${HARBOR_HOST}/k8s/${TAG##*/}"
    fi
  done
fi

# ---- containerd config output ----
cat <<EOF > containerd-harbor-config.conf
[plugins."io.containerd.grpc.v1.cri".registry.mirrors."$HARBOR_HOST"]
  endpoint = ["https://$HARBOR_HOST"]

[plugins."io.containerd.grpc.v1.cri".registry.configs."$HARBOR_HOST".tls]
  insecure_skip_verify = true
EOF

echo ""
echo "✅ Harbor install complete!"
echo "📝 containerd registry config written to: containerd-harbor-config.conf"
echo "   Manually append it to /etc/containerd/config.toml and restart containerd."