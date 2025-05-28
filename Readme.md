# CloudLens Agent Deployment with Ansible

## Overview

This repository provides Ansible playbooks to deploy the CloudLens Agent across Linux (Ubuntu) and Windows environments. For Linux, the playbook automates Docker installation and CloudLens container deployment. For Windows, it handles agent uninstallation (if previously installed), certificate management, and silent installation via the CloudLens executable. Also contain playbook to remove deployments and processes that was installed by cloudlens.

---

## Repository Contents

- `main.yaml` – For Linux VMs:
    - Installs and configures Docker.
    - Configures Docker daemon for secure/insecure registries.
    - Deploys the CloudLens Agent container.
- `windows.yaml` – For Windows VMs:
    - Ensures WinRM connectivity.
    - Automatically uninstalls existing CloudLens agent (if found).
    - Transfers and installs the CloudLens Windows executable.
    - Supports SSL verification using custom CA certificates.
- `vars.yaml` – Defines common variables:
    - CloudLens Manager IP or FQDN.
    - Project key.
    - Registry type: `secure` or `insecure`.
    - Local CA certificate path.
    - Logging options.
    - Windows installer paths and SSL settings.
- `inventory.ini` – Inventory file to list target hosts, grouped logically (e.g., `windows`, `onprem_vms`, `azure_vms`).
- `README.md` – This documentation.

---

## Prerequisites

### General
- **Ansible Control Machine**:
  - Ansible installed (2.9+).
- **Network Access**:
  - VMs must access CloudLens Manager and registry.

### For Linux VMs
- **Target OS**:
  - Ubuntu or similar.
- **SSH Access**:
  - Public key authentication with sudo rights.
- **Docker Runtime**:
  - Docker or compatible runtime pre-installed or installable.

### For Windows VMs
- **WinRM Enabled**:
  - WinRM over HTTPS (port 5986) must be enabled.
- **Firewall Rules**:
  - Must allow inbound WinRM traffic.
- **Admin Credentials**:
  - Must use a user with admin rights.
- **Disable NLA (optional)**:
  - Temporarily disable Network Level Authentication for easier initial setup.

---

## Setup and Configuration

### 1. Inventory File (`inventory.ini`)
Configure your hosts and group them appropriately.

### 2. Dry Run (Syntax Check)
```bash
ansible-playbook -i inventory.ini main.yaml --syntax-check
```

### 3. Python Interpreter Configuration (Linux)
Refer to [Ansible Interpreter Discovery Guide](https://docs.ansible.com/ansible-core/2.18/reference_appendices/interpreter_discovery.html) to avoid interpreter warnings.

### 4. Windows Deployment Considerations

#### ✅ Automatic Agent Cleanup
- The Windows playbook automatically detects and removes any existing CloudLens installation.

#### ✅ SSL Certificate Handling
- If `ssl_verify` is set to `yes`:
  - Your CA certificate (full chain) is uploaded to `C:\temp\cloudlens_ca.crt`
  - It is imported into the Trusted Root Certification Authorities store to ensure secure TLS validation.

#### ⚠️ Notes on SSL Verification
- If the certificate is invalid, expired, or not trusted, the installer will fail to validate the CloudLens Manager server.
- You **must** ensure your CA cert is up to date and properly chained.

#### ✅ Silent Agent Installation
- The playbook uses `/install /quiet` parameters with:
  - `Server` – IP/FQDN of your CloudLens Manager
  - `Project_Key` – Provided by your CloudLens setup
  - `SSL_Verify`, `Auto_Update`, and `Custom_Tags` are customizable

#### 🔁 Post-Install Cleanup (Optional)
- The agent installer and CA cert remain in `C:\temp\`. Consider adding tasks to delete them after deployment if needed.

---

## Example Variable Configuration (`vars.yaml`)
```yaml
cloudlens_manager_ip_or_FQDN: "20.12.10.80"
project_key: "c09b143bedd64a7fb3f0b138a409ff66"
custom_tags: "Env=Azure Region=US-East"

local_ca_path: "/Users/yourname/path/to/cloudlenscerts.crt"
registry_type: "secure"
ca_cert_dir: "/etc/ssl/certs"
cloudlens_agent_container_name: "cloudlens-agent"

# Windows-specific
local_installer_path: "/Users/yourname/Downloads/cloudlens-win-sensor-6.11.1.302.exe"
cloudlens_installer_filename: "cloudlens-win-sensor-6.11.1.302.exe"
ssl_verify: "yes"
auto_update: "yes"
log_max_size: "50m"
log_max_file: "5"
```

---

## Troubleshooting

- Set `OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES` to avoid macOS Python interpreter crashes.
- Ensure WinRM connectivity by testing with `ansible windows -i inventory.ini -m win_ping`.
- Check `silent_install_result.rc` and `.stdout` for success or errors after running the playbook.

---

## License
MIT or Company-Specific License.
