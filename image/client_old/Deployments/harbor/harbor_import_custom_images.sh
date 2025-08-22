#!/bin/bash
set -e

DOMAIN="harbor.local"
PROJECT="k8s"
USERNAME="admin"
PASSWORD="SuperSecretPass123"

IMAGES_DIR="./images"

docker login "$DOMAIN" -u "$USERNAME" -p "$PASSWORD"

for archive in "$IMAGES_DIR"/*.tar.gz; do
  [ -e "$archive" ] || continue
  echo "Loading $archive"
  docker load -i "$archive"

  IMAGE=$(docker images --format "{{.Repository}}:{{.Tag}}" | head -n 1)
  TARGET_IMAGE="$DOMAIN/$PROJECT/$(basename "$IMAGE")"
  docker tag "$IMAGE" "$TARGET_IMAGE"
  docker push "$TARGET_IMAGE"
done
