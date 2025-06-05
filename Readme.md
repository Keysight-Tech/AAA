# CloudLens Agent Deployment with Ansible

## Overview

This repository provides Ansible playbooks to deploy the CloudLens Agent across various environments, including:

- **Ubuntu/RHEL-based Linux virtual machines**  Tested and Supported over 500+ VMs across (Azure VMs, AWS, GCP, VMWare, Oracle, on-premise servers)
- **Windows virtual machines** (with WinRM and `.exe` installer support)

The Linux playbook automates Docker or Podman installation, container deployment, and registry authentication. The Windows playbook installs or uninstalls the CloudLens Agent `.exe` package via silent install.


---
# Note

   This playbook can support deployments to thousands of servers as needed.
---

## Scaling Deployments

For environments with hundreds or thousands of servers, consider using:

- Dynamic inventory plugins (cloud-native integration)
- Generated static inventories via scripting

📘 [Learn more about Ansible dynamic inventory plugins](https://docs.ansible.com/ansible/latest/plugins/inventory.html)

---

## 📁 Repository Structure

| File/Folder | Description |
|-------------|-------------|
| `ubuntu.yaml` | Deploy CloudLens agent on Ubuntu (Docker) |
| `redhat.yaml` | Deploy CloudLens agent on RHEL (Podman) |
| `windows.yaml` | Deploy CloudLens agent on Windows (.exe) |
| `ubuntu_cleanup.yaml` | Remove CloudLens agent and Docker from Ubuntu |
| `redhat_cleanup.yaml` | Remove CloudLens agent, Podman, and registry config |
| `windows_cleanup.yaml` | Uninstall CloudLens agent from Windows |
| `variables.yaml` | Global config (registry, project key, certs, tags) |
| `inventory.ini` | Target host definitions for Ansible |
| `ansible.cfg` | Ansible control configuration |
| `README.md` | This documentation file |


## Repository Contents

- `redhat.yaml,ubuntu.yaml`: Primary Linux playbook responsible for:
  - Installing and configuring Docker or Podman
  - Configuring insecure or secure registry settings
  - Deploying the CloudLens Agent container

- `windows.yaml`: Windows playbook for:
  - Creating deployment directory
  - Uninstalling CloudLens Agent if previously installed
  - Copying `.exe` installer to the target
  - Installing via silent command with custom tags and SSL options

- `variables.yaml`: Configuration variables such as:
  - CloudLens Manager address
  - Registry type (`secure` or `insecure`)
  - Project key and custom tags
  - Log rotation settings
  - Windows installer path, flags, and cert config

- `inventory.ini`: Target host list for Linux and Windows grouped by provider or OS

- `README.md`: This documentation file

---

## Prerequisites

## Installing Ansible on Your Control Node

### macOS
```bash
brew install ansible
```

### Ubuntu / Debian Linux
```bash
sudo apt update
sudo apt install -y ansible
```

### RHEL / CentOS Linux
```bash
sudo yum install -y epel-release
sudo yum install -y ansible
```

### Windows (via WSL or Virtual Environment)
1. Install WSL (Windows Subsystem for Linux)
2. Launch a WSL terminal (Ubuntu recommended)
3. Run:
```bash
sudo apt update
sudo apt install -y ansible
```

Alternatively, install Ansible via Python virtualenv:
```bash
python3 -m venv venv
source venv/bin/activate
pip install ansible==2.9.27
```

- **CloudLens Manager:**
  - Reachable from target VMs
  - Valid SSL certs (if `ssl_verify=yes`)

### Linux VMs
- SSH access enabled with sudo
- Docker- or Podman-compatible kernel
- Internet access or internal access to private container registry

### Windows VMs
- WinRM configured and enabled
- Firewall ports open for WinRM
- Network access to CloudLens Manager
- Local administrator privileges

---

## Setup and Configuration

### 1. Inventory File (`inventory.ini`)

```ini
[ubuntu_vms]
server1 ansible_host=172.200.141.103 #( replace with your ip addresses )

[redhat_vms]
server1 ansible_host=172.200.141.xx

[windows]
10.38.23.604

```

### 2. Variable File (`variables.yaml`)

```yaml
cloudlens_manager_ip_or_FQDN: "20.12.10.80"
project_key: "<PROJECT_KEY>"
custom_tags: "Env=Azure Region=US-East"
registry_type: "insecure"  # or "secure"
ssl_verify: "no"            # for Windows
local_installer_path: "/path/to/cloudlens-win-sensor.exe"
cloudlens_installer_filename: "cloudlens-win-sensor.exe"
```

> **Note:** Set `ssl_verify: "yes"` only if the CloudLens Manager uses a trusted SSL certificate.

---

## Linux Deployment Workflow

### For Ubuntu
- Installs and configures Docker
- Configures secure/insecure registry
- Deploys and verifies the CloudLens container

### For RHEL/CentOS (7 & 8+)
- **Uses Podman (preferred on Red Hat)**
- Conditional logic handles RHEL 7 (`yum`) and 8+ (`dnf`) for installing Podman and container tools
- Creates necessary directories: `/var/log/cloudlens`, `/var/tmp/cloudtap`
- Configures `registries.conf.d` for insecure registries or installs CA for secure ones
- Pulls the sensor image from CloudLens Manager
- Runs the container with correct capabilities and volume mappings
- Verifies the container is running

#### Best Practices for Red Hat
- Use `podman` instead of `docker` (no daemon requirement)
- Avoid `container-tools` on RHEL 8+ as Podman is installed directly
- Always check Red Hat version and conditionally apply package modules
- Use `--security-opt label=disable` for SELinux-enabled systems
- Mount necessary volumes (`/lib/modules`, `/var/log/cloudlens`, `/host`) for full visibility
- Ensure the `/etc/containers/registries.conf.d/cloudlens.conf` file is properly structured for `insecure` deployments

> **Note:** Podman does not have a daemon, so systemd services like `podman.socket` are only optionally used on RHEL 8+

#### Debugging
- If container fails to run, ensure `/var/tmp/cloudtap` and `/var/log/cloudlens` exist
- If image pull fails, check DNS and firewall access to CloudLens Manager
- Use `podman logs cloudlens-agent` for troubleshooting

---

## Windows Deployment Workflow

1. Create `C:\temp` on target if not present
2. Check if CloudLens Agent is already installed (via registry)
3. If present, uninstall silently using PowerShell
4. Copy installer `.exe` to `C:\temp`
5. Run silent install with required arguments:
   - Server IP or hostname
   - Project key
   - SSL verification flag (`yes` or `no`)
   - Custom tags
6. Display installation output
7. Fail the play if installation fails

> **Important for Windows:**
> - Ensure the `.exe` installer is correct and compatible
> - Ensure the VM can resolve and connect to `cloudlens_manager_ip_or_FQDN`
> - Use `ssl_verify: "no"` if using IP or a self-signed cert

---


## Deployment Commands

### Ubuntu Linux Deployment
```bash
ansible-playbook -i inventory.ini ubuntu.yaml
```

### RHEL/CentOS Deployment
```bash
ansible-playbook -i inventory.ini redhat.yaml
```

### Windows Deployment
```bash
ansible-playbook -i inventory.ini windows.yaml
```

### Cleanup - Ubuntu
```bash
ansible-playbook -i inventory.ini ubuntu_cleanup.yaml
```

### Cleanup - RHEL/CentOS
```bash
ansible-playbook -i inventory.ini redhat_cleanup.yaml
```

### Cleanup - Windows
```bash
ansible-playbook -i inventory.ini windows_cleanup.yaml
```

---

##  Ansible Logging Details

The Ansible configuration enables centralized logging of all playbook executions with the following setting in `ansible.cfg`:

```ini
log_path = ./ansible.log
```

### 📍 Location
All logs are written to:
```bash
./ansible.log
```

### 🔍 What This Log Contains
- SSH connection events
- Task execution results and errors
- Python interpreter discovery info
- Module stack traces and debug output
- Warnings and tracebacks

### 🧑‍🔧 Use Cases
- Troubleshooting failed playbooks
- Reviewing debug information
- Providing an audit trail of Ansible executions
- Diagnosing interpreter or module compatibility issues

--

## Useful Commands

- Dry run:
```bash
ansible-playbook -i inventory.ini playbook(e.g ubuntu.yaml) --syntax-check
```

- Set interpreter explicitly:
```ini
[all:vars]
ansible_python_interpreter=/usr/bin/python3
```

- More info: [Interpreter Discovery Guide](https://docs.ansible.com/ansible-core/2.18/reference_appendices/interpreter_discovery.html)

---

## Known Issues and Fixes

- **Python not found on remote host:**
> Fix by installing Python or specifying `ansible_python_interpreter`

- **Broken pipe / shared connection closed:**
> Typically SSH or resource timeout. Retry or increase timeout in `ansible.cfg`

- **`SyntaxError: future feature annotations is not defined`:**
> Ensure Python 3.6+ is used on control and target nodes

- **Podman directory errors:**
> Ensure `/var/tmp/cloudtap` and `/var/log/cloudlens` exist before container run

---

## Optional Cleanup (Post-Install)

### For Windows
```yaml
- name: Remove installer from temp
  win_file:
    path: "C:\\temp\\{{ cloudlens_installer_filename }}"
    state: absent
```

### For RHEL/CentOS
Use `redhat_cleanup.yaml` to:
- Remove container
- Remove image
- Delete registry configuration
- Remove CA cert and cloudtap/log folders

---

## Contact

Please raise issues or PRs to suggest improvements or fixes.

--

### Note

You should install pywinrm on your Host because:

🔧 **Ansible Always Runs from the Control Node (Your Mac)**
Ansible is agentless — it connects remotely to Windows (via WinRM) or Linux (via SSH).

So, all required Ansible Python packages (including pywinrm) must be installed on the machine where you're running Ansible — which is your PC.

The Windows VMs just need to have WinRM enabled and reachable.

```bash
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES