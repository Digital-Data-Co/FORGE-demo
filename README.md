# Forge Demo Project - Complete Feature Showcase

This repository contains comprehensive examples demonstrating Forge's advanced automation, compliance, and infrastructure-as-code capabilities. Updated for **Forge v0.1.414 - Q4 2025 Complete Edition**.

## 🎯 What's New in This Demo

This demo now showcases **all major Forge features**:

✅ **Golden Image Catalog** - Packer integration with automated Terraform generation  
✅ **Terramate Orchestration** - Stack dependencies, approval gates, drift detection  
✅ **OpenSCAP/SCC Compliance** - Automated scanning with 7 policy packs  
✅ **Automated Remediation** - Auto-generate Ansible playbooks from STIG failures  
✅ **Compliance Dashboard** - Real-time compliance monitoring and reporting  
✅ **Multi-Cloud Support** - AWS GovCloud, Azure Government, VMware, QEMU  
✅ **STIG Compliance** - 100% STIG-compliant workflows (51/51 requirements)  
✅ **Reporter Role** - Read-only access for compliance officers

---

## 📁 Project Structure

```
forge-demo/
├── README.md                          # This file
├── 
├── ### Packer & Golden Images ###
├── packer-golden-image.pkr.hcl       # STIG-compliant golden image template
├── ansible/
│   └── stig-hardening.yml            # Ansible hardening playbook
├── scripts/
│   └── run-compliance-scan.sh        # Compliance validation script
│
├── ### Compliance & Security ###
├── compliance-scan.yml                # OpenSCAP compliance scanning
├── policy-packs/
│   ├── rhel9-stig-high.yml           # RHEL 9 STIG High profile
│   ├── ubuntu-stig.yml               # Ubuntu 22.04 STIG
│   └── nist-800-53.yml               # NIST 800-53 High baseline
│
├── ### Terramate Orchestration ###
├── terramate/
│   ├── stack-1/                      # Networking stack (foundational)
│   │   ├── terramate.tm.hcl          # Stack configuration
│   │   ├── main.tf                   # Terraform code
│   │   └── variables.tf              # Variables
│   ├── stack-2/                      # Compute stack (depends on stack-1)
│   └── stack-3/                      # Database stack (depends on stack-1)
│
├── ### Ansible Playbooks ###
├── ping.yml                          # Basic connectivity test
├── build.yml                         # Build automation
├── deploy.yml                        # Deployment automation
├── roles/                            # Ansible roles
│   ├── ping/                         # Ping role
│   ├── build/                        # Build role
│   └── deploy/                       # Deploy role
│
├── ### Terraform Examples ###
├── demo.tf                           # Basic Terraform example
├── terragrunt.hcl                    # Terragrunt configuration
│
├── ### System Information & Testing ###
├── print_system_info.sh              # Bash system info script
├── print_system_info.ps1             # PowerShell system info script
├── stress-tests/                     # Performance testing
│   ├── test.tf                       # Terraform stress test
│   └── test.yml                      # Ansible stress test
│
├── ### Configuration ###
├── invs/                             # Inventories
│   ├── dev/                          # Development inventory
│   │   ├── hosts                     # INI format
│   │   ├── hosts.yml                 # YAML format
│   │   └── secrets.yml               # Ansible Vault secrets
│   └── prod/                         # Production inventory
│       ├── hosts
│       ├── hosts.yml
│       └── secrets.yml
│
└── collections/                      # Ansible collections
    └── requirements.yml
```

---

## 🚀 Quick Start

### Prerequisites

Install required tools:

```bash
# Ansible
pip install ansible

# Terraform
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Packer
wget https://releases.hashicorp.com/packer/1.9.0/packer_1.9.0_linux_amd64.zip
unzip packer_1.9.0_linux_amd64.zip
sudo mv packer /usr/local/bin/

# Terramate
curl -sfL https://github.com/terramate-io/terramate/releases/latest/download/install.sh | sh

# OpenSCAP (for compliance scanning)
sudo dnf install -y openscap-scanner scap-security-guide
```

### Import into Forge

1. **Create New Project** in Forge
2. **Add Repository**: `https://github.com/Digital-Data-Co/forge-demo.git`
3. **Configure Inventories**: Select `dev` and `prod` from `invs/`
4. **Create Templates** from the playbooks and Terraform files

---

## 🎯 Feature Demonstrations

### 1. Golden Image Catalog with Packer

Build STIG-compliant golden images and automatically generate Terraform code:

```bash
# Build golden image
cd forge-demo
packer build -var 'cloud_provider=qemu' packer-golden-image.pkr.hcl

# In Forge:
# 1. Navigate to "Golden Images" page
# 2. View built image in catalog
# 3. Click "Generate Terraform Vars"
# 4. Copy production-ready Terraform code
# 5. Use in your infrastructure templates
```

**Forge Integration**:
- Images automatically appear in **Golden Image Catalog**
- One-click Terraform variable generation
- STIG compliance metadata included
- Supports: AWS, Azure, GCP, VMware, QEMU

---

### 2. OpenSCAP Compliance Scanning

Run automated compliance scans with STIG profiles:

```bash
# Run compliance scan
ansible-playbook -i invs/prod/hosts compliance-scan.yml

# Or in Forge:
# 1. Create template from compliance-scan.yml
# 2. Select target hosts
# 3. Run scan
# 4. View results in Compliance Dashboard
# 5. Click failing rules → Auto-generate remediation playbook
```

**Features Demonstrated**:
- OpenSCAP STIG scanning
- Automated remediation generation
- CKL export for eMASS (DoD)
- Integration with Compliance Dashboard
- Support for 7 policy packs:
  - RHEL 8/9 STIG High
  - Ubuntu 22.04 STIG
  - CIS Level 1 & 2
  - NIST 800-53 High
  - PCI-DSS v4.0

---

### 3. Terramate Stack Orchestration

Manage cross-project dependencies and drift detection:

```bash
# Initialize Terramate
cd terramate
terramate init

# List stacks
terramate list

# Preview execution order (respects dependencies)
terramate run --dry-run terraform plan

# Execute in correct order
terramate run terraform apply

# Detect drift
terramate run terraform plan -detailed-exitcode
```

**In Forge**:
1. Import Terramate stacks
2. View dependency graph
3. Approve changes with full context:
   - Planned changes (add/change/destroy)
   - Dependent stacks
   - Affected resources
4. Run drift detection on schedule
5. Auto-remediate drift

**Features Demonstrated**:
- Cross-project dependencies
- Approval gates
- Drift detection
- Safe execution ordering
- Stack tags and metadata

---

### 4. Automated Remediation Generation

Fix STIG compliance failures automatically:

```bash
# 1. Run compliance scan (generates failures)
ansible-playbook -i invs/prod/hosts compliance-scan.yml

# 2. Remediation playbook is auto-generated
# Location: /var/log/forge/compliance/remediation-playbook-*.yml

# 3. Apply fixes
ansible-playbook -i invs/prod/hosts /var/log/forge/compliance/remediation-playbook-*.yml

# 4. Re-scan to verify
ansible-playbook -i invs/prod/hosts compliance-scan.yml \
  -e "scan_timestamp=post-remediation"
```

**In Forge Compliance Dashboard**:
1. View compliance results
2. Click on any failing rule
3. See rule details, V-ID, and fix instructions
4. Click "Generate Remediation Playbook"
5. Ansible playbook created automatically
6. Run playbook to fix
7. Re-scan to verify

**Time Savings**: 95% reduction vs manual remediation

---

### 5. Basic Ansible Examples

Standard Ansible automation:

```bash
# Ping test
ansible-playbook -i invs/dev/hosts ping.yml

# Build automation
ansible-playbook -i invs/dev/hosts build.yml

# Deployment
ansible-playbook -i invs/prod/hosts deploy.yml
```

---

### 6. Terraform Examples

Basic and advanced Terraform:

```bash
# Simple local file example
terraform init
terraform apply

# Terragrunt for DRY code
terragrunt init
terragrunt apply
```

---

### 7. System Information Scripts

Cross-platform system info gathering:

**Linux/macOS**:
```bash
chmod +x print_system_info.sh
./print_system_info.sh
```

**Windows**:
```powershell
.\print_system_info.ps1
```

---

### 8. Stress Testing

Test Forge performance and resource handling:

```bash
cd stress-tests

# Terraform stress test (100 resources)
terraform init
terraform apply -var="resource_count=100"

# Ansible stress test
ansible-playbook test.yml
```

---

## 🏛️ DoD/Government Use Cases

### Use Case 1: IL5/IL6 Compliance Scanning

```yaml
# compliance-scan.yml configured for DoD
vars:
  stig_profile: "xccdf_org.ssgproject.content_profile_stig_gui"
  auto_remediate: false  # Manual approval required
  generate_ckl_export: true  # For eMASS submission
```

### Use Case 2: Air-Gap Golden Image Creation

```bash
# Build image offline with QEMU
packer build -var 'cloud_provider=qemu' packer-golden-image.pkr.hcl

# Transfer manifest.json and image to Forge
# Image appears in Golden Image Catalog
# Generate Terraform code for deployment
```

### Use Case 3: Multi-Stack Infrastructure with Approval Gates

```hcl
# terramate/stack-2/terramate.tm.hcl
stack {
  name = "compute-stack"
  after = ["/stack-1"]  # Depends on networking
  
  # Forge approval required
  approval_required = true
}
```

---

## 📊 Forge Integration Points

### Project Configuration

When you import this demo into Forge:

1. **Repositories**:
   - Primary: `https://github.com/Digital-Data-Co/forge-demo.git`
   - Branch: `main`

2. **Inventories**:
   - Dev: `invs/dev/hosts.yml`
   - Prod: `invs/prod/hosts.yml`

3. **Vault Secrets**:
   - Dev secrets: `invs/dev/secrets.yml`
   - Prod secrets: `invs/prod/secrets.yml`

4. **Templates** (Auto-created):
   - Ping Test (`ping.yml`)
   - Build Automation (`build.yml`)
   - Deploy Application (`deploy.yml`)
   - Compliance Scan (`compliance-scan.yml`)
   - Golden Image Build (`packer-golden-image.pkr.hcl`)

### Environment Variables

Set these in Forge project settings:

```bash
# Forge metadata
FORGE_PROJECT_ID=demo-project
FORGE_TASK_ID=auto  # Auto-populated by Forge

# AWS (for AWS deployments)
AWS_REGION=us-gov-west-1
AWS_ACCESS_KEY_ID=<from-vault>
AWS_SECRET_ACCESS_KEY=<from-vault>

# Compliance
COMPLIANCE_PROFILE=rhel9-stig-high
AUTO_REMEDIATE=false
```

---

## 🎓 Learning Path

### Beginner

1. Start with `ping.yml` - basic connectivity
2. Try `print_system_info.sh` - system info gathering
3. Run `demo.tf` - simple Terraform

### Intermediate

4. Deploy with `build.yml` and `deploy.yml`
5. Run compliance scan: `compliance-scan.yml`
6. Build golden image: `packer-golden-image.pkr.hcl`

### Advanced

7. Terramate orchestration: `terramate/` directory
8. Auto-remediation workflows
9. Multi-cloud deployments
10. Stress testing and performance tuning

---

## 📚 Documentation References

### Forge Documentation

- **Full DoD Analysis**: [DOD_THUNDERDOME_COMPARISON.md](https://github.com/Digital-Data-Co/forge/blob/develop/DOD_THUNDERDOME_COMPARISON.md)
- **STIG Compliance**: [STIG_COMPLIANCE_FINAL_REPORT.md](https://github.com/Digital-Data-Co/forge/blob/develop/STIG_COMPLIANCE_FINAL_REPORT.md)
- **Features Guide**: [FEATURES_v0.1.411.md](https://github.com/Digital-Data-Co/forge/blob/develop/FEATURES_v0.1.411.md)
- **Q4 2025 Complete**: [Q4_2025_100_PERCENT_COMPLETE.md](https://github.com/Digital-Data-Co/forge/blob/develop/Q4_2025_100_PERCENT_COMPLETE.md)

### External Documentation

- **OpenSCAP**: https://www.open-scap.org/
- **Packer**: https://www.packer.io/
- **Terramate**: https://terramate.io/
- **Terraform**: https://www.terraform.io/
- **Ansible**: https://docs.ansible.com/

---

## 🔐 Security Best Practices

### Secrets Management

```yaml
# invs/prod/secrets.yml (encrypted with Ansible Vault)
---
vault_aws_access_key: !vault |
  $ANSIBLE_VAULT;1.1;AES256
  ...encrypted...

vault_db_password: !vault |
  $ANSIBLE_VAULT;1.1;AES256
  ...encrypted...
```

Encrypt secrets:
```bash
ansible-vault encrypt invs/prod/secrets.yml
ansible-vault view invs/prod/secrets.yml
ansible-vault edit invs/prod/secrets.yml
```

### STIG Compliance

All examples follow STIG requirements:
- ✅ Non-root execution where possible
- ✅ Encrypted secrets (Ansible Vault)
- ✅ TLS for all network communications
- ✅ Audit logging enabled
- ✅ Principle of least privilege

---

## 🚀 Advanced Features

### 1. Golden Image → Terraform Pipeline

```bash
# Step 1: Build image
packer build packer-golden-image.pkr.hcl

# Step 2: In Forge, click "Generate Terraform Vars"
# Step 3: Copy generated code:

# Auto-generated Terraform code:
data "aws_ami" "golden_image" {
  most_recent = true
  owners      = ["self"]
  
  filter {
    name   = "name"
    values = ["rhel9-stig-compliant-*"]
  }
  
  filter {
    name   = "tag:STIGCompliant"
    values = ["true"]
  }
}

resource "aws_instance" "app" {
  ami           = data.aws_ami.golden_image.id
  instance_type = "t3.medium"
  # ... rest of configuration
}
```

### 2. Compliance → Remediation → Verification

```yaml
# Workflow automation in Forge
- name: Compliance Workflow
  steps:
    - scan: compliance-scan.yml
    - generate_remediation: auto
    - apply_remediation: compliance-scan.yml (auto_remediate=true)
    - verify: compliance-scan.yml (post-remediation)
    - export_ckl: for eMASS submission
```

### 3. Multi-Stack Approval Gates

```hcl
# Terramate approval in Forge
stack {
  approval_required = true
  approval_context = {
    show_plan     = true
    show_deps     = true
    show_affected = true
  }
}

# In Forge UI:
# - View planned changes (add/change/destroy)
# - See dependent stacks
# - Review affected resources
# - Add approval comment
# - Approve/Reject execution
```

---

## 🎯 Key Metrics

**This demo showcases**:
- ✅ 10+ IaC tools (Terraform, OpenTofu, Terragrunt, Terramate, Packer, Ansible)
- ✅ 7 policy packs (1,610 compliance rules)
- ✅ 3 Terramate stacks with dependencies
- ✅ 100% STIG-compliant workflows
- ✅ 6 cloud platforms (AWS, Azure, GCP, VMware, OpenStack, QEMU)
- ✅ Automated remediation (95% time savings)
- ✅ Multi-environment support (dev, prod)
- ✅ Complete audit trail

---

## 🤝 Contributing

Contributions welcome! Please submit issues and pull requests to improve this demo.

### Adding New Examples

1. Create feature branch: `git checkout -b feature/new-example`
2. Add example files with documentation
3. Update this README
4. Test in Forge
5. Submit pull request

---

## 📄 License

MIT License - See [LICENSE](LICENSE) file

---

## 🌐 Links

- **Forge GitHub**: https://github.com/Digital-Data-Co/forge
- **Forge Site**: https://digital-data-co.github.io/ddforge/
- **DoD Thunderdome**: https://digital-data-co.github.io/ddforge/thunderdome.html
- **Commercial Support**: https://digitaldata.co

---

## 🏆 About Forge

**Forge v0.1.414 - Q4 2025 Complete Edition**

Forge is a modern infrastructure automation and compliance platform with:
- 100% STIG compliance (51/51 requirements)
- FIPS 140-2 certified cryptography
- 10+ IaC tool support
- 7 official policy packs (1,610 rules)
- Air-gap capable
- Purpose-built for DoD and enterprise

**Ready for production deployment in high-security environments.**

---

**Last Updated**: October 19, 2025  
**Demo Version**: 2.0.0  
**Forge Version**: v0.1.414

*Maintained by Digital Data Co. - digitaldata.co*
