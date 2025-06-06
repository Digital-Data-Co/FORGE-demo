#!/bin/bash
set -e

DOMAIN="harbor.local"
PROJECT="k8s"
USERNAME="admin"
PASSWORD="SuperSecretPass123"
IMPORT_DIR="./exported-images"

docker login "$DOMAIN" -u "$USERNAME" -p "$PASSWORD"

for archive in "$IMPORT_DIR"/*.tar.gz; do
  docker load -i "$archive"

  IMAGE=$(docker images --format "{{.Repository}}:{{.Tag}}" | head -n 1)
  TARGET="$DOMAIN/$PROJECT/$(basename "$IMAGE")"
  docker tag "$IMAGE" "$TARGET"
  docker push "$TARGET"
done
