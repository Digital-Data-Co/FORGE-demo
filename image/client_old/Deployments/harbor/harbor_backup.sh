#!/bin/bash
set -e

EXPORT_DIR="./exported-images"
mkdir -p "$EXPORT_DIR"

images=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep harbor.local)

for img in $images; do
  base=$(basename "$img" | tr ':' '_')
  docker save "$img" | gzip > "$EXPORT_DIR/$base.tar.gz"
done
