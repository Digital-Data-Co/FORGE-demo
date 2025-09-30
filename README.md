# Forge Demo Project

This repository contains a collection of example projects demonstrating various automation and infrastructure-as-code tools integration with Forge. The project serves as a practical reference for implementing different automation workflows.

## Project Structure

The repository includes examples for the following technologies:

### Ansible

* `roles/` - Contains Ansible roles
* `invs/` - Inventory files for Ansible
* `collections/` - Ansible collections
* `ping.yml` - Basic Ansible playbook for connectivity testing
* `build.yml` - Build automation playbook
* `deploy.yml` - Deployment automation playbook

### Terraform

* `demo.tf` - Example Terraform configuration demonstrating local file resource
* `terragrunt.hcl` - Terragrunt configuration file

### System Information Scripts

* `print_system_info.sh` - Bash script for system information gathering  
   * Detects operating system  
   * Displays CPU information  
   * Shows memory usage  
   * Reports disk space

### Stress Tests

Located in the `stress-tests/` directory, these files are designed to test system performance and resource utilization:

* `test.tf` - Terraform-based stress test  
   * Creates multiple null resources (default: 100)  
   * Generates dummy files to test file system performance  
   * Uses local-exec provisioner to simulate workload  
   * Configurable resource count through variables
* `test.yml` - Ansible-based stress test playbook

## Prerequisites

* Ansible (for Ansible examples)
* Terraform (for Terraform examples)
* Bash shell (for shell scripts)
* PowerShell 5.1+ (for PowerShell scripts)
* Python 3.x (for Python examples)

## Usage

### Ansible Examples

```bash
# Run the ping playbook
ansible-playbook -i invs/dev/hosts ping.yml

# Execute build automation
ansible-playbook build.yml

# Run deployment
ansible-playbook deploy.yml
```

### Terraform Examples

```bash
# Initialize Terraform
terraform init

# Apply the configuration
terraform apply
```

### System Information Scripts

#### Bash Script (Linux/macOS)

```bash
# Make the script executable
chmod +x print_system_info.sh

# Run the script
./print_system_info.sh
```

#### PowerShell Script (Windows)

```powershell
# Run the script
.\print_system_info.ps1
```

### Stress Tests

```bash
# Navigate to stress tests directory
cd stress-tests

# Run Terraform stress test
terraform init
terraform apply

# Run Ansible stress test
ansible-playbook test.yml
```

## Forge Integration

This demo project is designed to work with Forge's demo project creation feature. When you create a demo project in Forge, it will:

1. Clone this repository
2. Set up the necessary inventories (dev, prod)
3. Create templates for ping, build, and deploy operations
4. Configure vault passwords for secure deployments

## Contributing

Feel free to submit issues and enhancement requests!

## License

MIT © Digital Data Co

## About

Collection of example projects demonstrating various automation and infrastructure-as-code tools integration with Forge.

digitaldata.co