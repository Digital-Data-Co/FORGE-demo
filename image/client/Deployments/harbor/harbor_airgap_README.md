# Harbor Airgap Deployment Bundle

This archive contains all necessary scripts and configuration files to install, configure, and manage a Harbor registry in an airgapped (offline) environment.

## Contents

- `harbor_install.sh`: Installs Harbor, configures users, preloads images, and sets up containerd.
- `harbor_extract_airgap.sh`: Exports Harbor project images and metadata for offline use.
- `harbor_restore_airgap.sh`: Restores Harbor projects and images from a previously exported airgap archive.
- `load_push_images.sh`: Loads custom `.tar.gz` Docker images and pushes them into Harbor.
- `ansible/roles/harbor/tasks/main.yml`: Ansible role to automate Harbor installation.
- `ansible/roles/harbor/templates/harbor.yml.j2`: Template configuration for Harbor.
- `README.md`: This documentation.

## Usage Instructions

### 1. Install Harbor

```bash
chmod +x harbor_install.sh
./harbor_install.sh
```

### 2. Export Harbor for Airgap

```bash
chmod +x harbor_extract_airgap.sh
./harbor_extract_airgap.sh
```

### 3. Restore Harbor in Another Airgapped System

```bash
chmod +x harbor_restore_airgap.sh
./harbor_restore_airgap.sh
```

### 4. Load and Push Custom Images

Place your `.tar.gz` images in the `images/` directory and run:

```bash
chmod +x load_push_images.sh
./load_push_images.sh
```

## Notes

- Ensure `harbor.local` resolves correctly in your environment (e.g., edit `/etc/hosts`).
- Self-signed SSL certs are used; update containerd or Docker to trust them.
- Make sure to run these scripts with root privileges or via `sudo`.

## Contacts

For any further configuration or troubleshooting, refer to [https://goharbor.io](https://goharbor.io)