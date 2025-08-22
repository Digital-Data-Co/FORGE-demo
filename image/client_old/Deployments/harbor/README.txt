# Harbor Airgapped Deployment README

Welcome to your self-contained Harbor registry deployment for disconnected environments.

---

## 🚀 Overview

This package provides everything needed to:

- Install Harbor with HTTPS support and Trivy scanning
- Load custom container images
- Configure containerd registry mirroring
- Create users and projects
- Export/import Harbor image bundles for airgap transfers

---

## 🧰 Included Scripts

### `install_harbor.sh`
Installs Harbor, configures SSL, enables Trivy, and generates `harbor.yml`.

### `add_users.sh`
Creates users:
- Dave Nelson (`dnelson`)
- Brandon Adamek (`badamek`)

And grants them access to the `k8s` project.

### `export_airgap_bundle.sh`
Exports all Harbor images to `exported-images/` as `.tar.gz` archives.

### `restore_airgap_bundle.sh`
Restores all previously saved `.tar.gz` archives back into Harbor.

### `import_custom_images.sh`
Loads local `.tar.gz` Docker images and pushes them to Harbor under the `k8s` project.

---

## 📦 RHEL 9 RPM Support

To prepare RHEL 9 in an airgapped environment:

1. Use the airgap script (`download_rpms.sh`) to collect required RPMs:
   - `docker`, `docker-compose`, `openssl`, and dependencies
2. Transfer the resulting `.rpm` packages to the target system
3. Install with:
   ```bash
   sudo dnf install *.rpm
