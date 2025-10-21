# Forge Demo - Golden Image with Packer
# This template demonstrates STIG-compliant golden image creation for the Golden Image Catalog

packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/qemu"
    }
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
    azure = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/azure"
    }
  }
}

# Variables
variable "image_name" {
  type    = string
  default = "rhel9-stig-compliant"
}

variable "image_version" {
  type    = string
  default = "1.0.0"
}

variable "cloud_provider" {
  type    = string
  default = "qemu"
  description = "Target cloud provider: qemu, aws, azure, gcp, vmware"
}

# Local variables
locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
  image_tags = {
    Name          = var.image_name
    Version       = var.image_version
    STIGCompliant = "true"
    BuildDate     = local.timestamp
    Compliance    = "RHEL-9-STIG"
    ForgeManaged  = "true"
  }
}

# QEMU/KVM Builder (for local testing and air-gap environments)
source "qemu" "rhel9" {
  iso_url          = "file:///path/to/rhel-9.iso"
  iso_checksum     = "sha256:abc123..."
  output_directory = "output-rhel9-qemu"
  shutdown_command = "sudo shutdown -P now"
  disk_size        = "40G"
  format           = "qcow2"
  accelerator      = "kvm"
  vm_name          = "${var.image_name}-${var.image_version}.qcow2"
  
  # Network configuration
  net_device = "virtio-net"
  disk_interface = "virtio"
  
  # Boot configuration
  boot_wait    = "10s"
  boot_command = [
    "<tab> text ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg<enter><wait>"
  ]
  
  # SSH configuration
  ssh_username = "packer"
  ssh_password = "packer"
  ssh_timeout  = "20m"
}

# AWS AMI Builder
source "amazon-ebs" "rhel9" {
  ami_name      = "${var.image_name}-${var.image_version}-${local.timestamp}"
  instance_type = "t3.medium"
  region        = "us-gov-west-1"
  
  source_ami_filter {
    filters = {
      name                = "RHEL-9*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["309956199498"] # Red Hat
  }
  
  ssh_username = "ec2-user"
  
  tags = local.image_tags
  
  # Encryption for compliance
  encrypt_boot = true
  kms_key_id   = "alias/forge-ami-encryption"
}

# Azure Image Builder
source "azure-arm" "rhel9" {
  managed_image_name                = "${var.image_name}-${var.image_version}"
  managed_image_resource_group_name = "forge-golden-images"
  
  os_type         = "Linux"
  image_publisher = "RedHat"
  image_offer     = "RHEL"
  image_sku       = "9_0"
  
  location = "usgovvirginia"
  vm_size  = "Standard_D2s_v3"
  
  azure_tags = local.image_tags
}

# Build configuration
build {
  name = "forge-golden-image"
  
  sources = [
    "source.qemu.rhel9",
    "source.amazon-ebs.rhel9",
    "source.azure-arm.rhel9"
  ]
  
  # Update system
  provisioner "shell" {
    inline = [
      "sudo dnf update -y",
      "sudo dnf install -y openscap-scanner scap-security-guide",
    ]
  }
  
  # Apply STIG hardening with Ansible
  provisioner "ansible" {
    playbook_file = "./ansible/stig-hardening.yml"
    extra_arguments = [
      "--extra-vars",
      "stig_profile=rhel9-stig-high"
    ]
  }
  
  # Run OpenSCAP compliance scan
  provisioner "shell" {
    script = "./scripts/run-compliance-scan.sh"
  }
  
  # Cleanup
  provisioner "shell" {
    inline = [
      "sudo dnf clean all",
      "sudo rm -rf /tmp/*",
      "sudo rm -rf /var/log/*",
      "sudo rm -f /root/.bash_history",
      "sudo rm -f /home/*/.bash_history"
    ]
  }
  
  # Create manifest for Forge Golden Image Catalog
  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
    custom_data = {
      stig_compliant = "true"
      stig_profile   = "RHEL-9-STIG-HIGH"
      build_date     = local.timestamp
      forge_managed  = "true"
      image_type     = "golden-image"
    }
  }
}

# Output for Forge integration
output "image_info" {
  value = {
    name      = var.image_name
    version   = var.image_version
    timestamp = local.timestamp
    provider  = var.cloud_provider
  }
}

