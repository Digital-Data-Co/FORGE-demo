#!/bin/bash
set -euo pipefail

# === CONFIGURATION ===
HARBOR_VERSION="v2.10.0"
K8S_VERSION="v1.32.5"
CALICO_VERSION="v3.30.1"
NETSHOOT_VERSION="latest"
HOSTNAME="harbor.local"
HTTP_PORT=80
HTTPS_PORT=8443
ADMIN_PASSWORD="Harbor12345"
INSTALL_DIR="/opt/harbor"
CERT_DIR="${INSTALL_DIR}/certs"
DOCKER_CERT_DIR="/etc/docker/certs.d/${HOSTNAME}:${HTTPS_PORT}"
IMAGE_DIR="${INSTALL_DIR}/harbor-images"
TEST_IMAGE="alpine"
TEST_REPO="library/alpine"

# === PHASE 1: IMAGE PULL AND SAVE ===
echo "[+] Creating image directory..."
mkdir -p "$IMAGE_DIR"

ALL_IMAGES=(
  # Kubernetes core
  "registry.k8s.io/kube-apiserver:${K8S_VERSION}"
  "registry.k8s.io/kube-controller-manager:${K8S_VERSION}"
  "registry.k8s.io/kube-scheduler:${K8S_VERSION}"
  "registry.k8s.io/kube-proxy:${K8S_VERSION}"
  "registry.k8s.io/pause:3.10"
  "registry.k8s.io/etcd:3.5.12"
  "registry.k8s.io/coredns/coredns:v1.11.1"

  # Calico
  "docker.io/calico/cni:${CALICO_VERSION}"
  "docker.io/calico/kube-controllers:${CALICO_VERSION}"
  "docker.io/calico/node:${CALICO_VERSION}"
  "docker.io/calico/typha:${CALICO_VERSION}"
  "docker.io/calico/apiserver:${CALICO_VERSION}"

  # Harbor
  "goharbor/harbor-core:${HARBOR_VERSION}"
  "goharbor/harbor-portal:${HARBOR_VERSION}"
  "goharbor/harbor-jobservice:${HARBOR_VERSION}"
  "goharbor/harbor-db:${HARBOR_VERSION}"
  "goharbor/harbor-registryctl:${HARBOR_VERSION}"
  "goharbor/harbor-registry:${HARBOR_VERSION}"
  "goharbor/redis-photon:${HARBOR_VERSION}"
  "goharbor/trivy-adapter-photon:${HARBOR_VERSION}"
  "goharbor/nginx-photon:${HARBOR_VERSION}"

  # Troubleshooting
  "nicolaka/netshoot:${NETSHOOT_VERSION}"
)

echo "[+] Pulling and saving all images..."
for IMAGE in "${ALL_IMAGES[@]}"; do
  TAG=$(echo "$IMAGE" | sed 's|[/:]|_|g')
  TAR="${IMAGE_DIR}/${TAG}.tar"
  echo "[>] Pulling $IMAGE"
  docker pull "$IMAGE"
  echo "[>] Saving $IMAGE -> $TAR"
  docker save "$IMAGE" -o "$TAR"
done

# === PHASE 2: CERT GENERATION ===
echo "[+] Creating cert directory..."
mkdir -p "$CERT_DIR"

echo "[+] Generating TLS certificate for $HOSTNAME..."
openssl req -x509 -nodes -days 365 \
  -subj "/C=US/ST=IL/L=Chicago/O=IL6/CN=${HOSTNAME}" \
  -addext "subjectAltName = DNS:${HOSTNAME}" \
  -newkey rsa:4096 \
  -keyout "${CERT_DIR}/tls.key" \
  -out "${CERT_DIR}/tls.crt"

echo "[+] Installing cert to Docker trust store..."
mkdir -p "$DOCKER_CERT_DIR"
cp "${CERT_DIR}/tls.crt" "${DOCKER_CERT_DIR}/ca.crt"
systemctl restart docker || echo "[!] Could not restart Docker—please restart it manually"

# === PHASE 3: HARBOR INSTALL ===
echo "[+] Setting up Harbor install..."
cd "$INSTALL_DIR"
if [[ ! -f harbor-online-installer-${HARBOR_VERSION}.tgz ]]; then
  curl -LO https://github.com/goharbor/harbor/releases/download/${HARBOR_VERSION}/harbor-online-installer-${HARBOR_VERSION}.tgz
fi
tar -xzf harbor-online-installer-${HARBOR_VERSION}.tgz
cd harbor

echo "[+] Writing harbor.yml..."
cat <<EOF > harbor.yml
hostname: ${HOSTNAME}

http:
  port: ${HTTP_PORT}

https:
  port: ${HTTPS_PORT}
  certificate: ${CERT_DIR}/tls.crt
  private_key: ${CERT_DIR}/tls.key

harbor_admin_password: ${ADMIN_PASSWORD}

internal_tls:
  enabled: true

database:
  password: root123

data_volume: /data

trivy:
  ignoreUnfixed: true
  skipUpdate: true
  insecure: false

log:
  level: info

_version: ${HARBOR_VERSION}
EOF

echo "[+] Running prepare script..."
./prepare

echo "[+] Starting Harbor..."
docker-compose up -d

echo "[+] Waiting 15 seconds for services to stabilize..."
sleep 15

# === PHASE 4: TEST PUSH/PULL ===
echo "[+] Pulling test image and tagging for Harbor..."
docker pull $TEST_IMAGE
docker tag $TEST_IMAGE ${HOSTNAME}:${HTTPS_PORT}/${TEST_REPO}

echo "[+] Logging into Harbor registry..."
docker login ${HOSTNAME}:${HTTPS_PORT} -u admin -p ${ADMIN_PASSWORD}

echo "[+] Pushing image to Harbor..."
docker push ${HOSTNAME}:${HTTPS_PORT}/${TEST_REPO}

echo "[+] Removing local image and pulling from Harbor..."
docker rmi ${HOSTNAME}:${HTTPS_PORT}/${TEST_REPO}
docker pull ${HOSTNAME}:${HTTPS_PORT}/${TEST_REPO}

# === DONE ===
echo "[✓] Harbor fully installed with TLS and Trivy."
echo "[→] Access at: https://${HOSTNAME}:${HTTPS_PORT}"
echo "[→] Default credentials: admin / ${ADMIN_PASSWORD}"
echo "[→] Add to /etc/hosts if not resolvable: 127.0.0.1 ${HOSTNAME}"
