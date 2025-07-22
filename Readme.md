# CloudLens Agent Deployment with Ansible

## Overview

This repository provides fully automated Ansible playbooks for deploying the CloudLens Agent across various platforms:

- **Linux (Ubuntu, RHEL/CentOS)** – Docker or Podman-based container deployment.
- **Windows** – `.exe` silent installation over WinRM.

The automation covers every step from initial setup to agent health validation:

- ✅ Container engine installation (Docker or Podman)  
- ✅ Registry trust configuration and authentication  
- ✅ Deployment of the agent (container or executable)  
- ✅ Structured logging, health checks, and clean-up routines  

## ⚠️ Note

This deployment framework supports scaling to thousands of servers across hybrid infrastructures using either static inventories, dynamic inventory plugins, **Ansible Tower/AWX**, and is optimized for **NSX-T** managed environments.

---

## 📈 Scaling Deployments

For large-scale infrastructure:
- Use dynamic inventories leveraging **NSX-T tags** and **vCenter inventory**
- Integrate with **Ansible Tower** for centralized job management and scheduling
- Use `constructed.yaml` to group VMs dynamically based on NSX-T security tags and logical constructs
- Leverage Tower's **survey features** for parameterized deployments

📘 **[Explore Ansible dynamic inventory plugins](https://docs.ansible.com/ansible/latest/plugins/inventory.html)**

---

## 📁 Repository Structure

| File/Folder               | Description                                                             |
|---------------------------|-------------------------------------------------------------------------|
| `ubuntu.yaml`             | Deploy CloudLens Agent on Ubuntu                                       |
| `redhat.yaml`             | Deploy CloudLens Agent on RHEL with Podman                             |
| `windows.yaml`            | Deploy CloudLens Agent on Windows via `.exe` installer                 |
| `ubuntu_cleanup.yaml`     | Remove Docker and agent from Ubuntu                                    |
| `redhat_cleanup.yaml`     | Remove Podman, agent, and config from RHEL                             |
| `windows_cleanup.yaml`    | Uninstall agent from Windows and remove installer                      |
| `inventory/group_vars/`   | Group-specific variables per OS/environment                            |
| `inventory/azure_rm.yaml` | Dynamic inventory configuration (example for cloud providers)           |
| `constructed.yaml`        | Build dynamic groups based on NSX-T tags                               |
| `ansible.cfg`             | Ansible config including SSH key path, logging, etc.                   |
| `deploy.yaml`             | Master deployment sequence across all environments                     |
| `cleanup.yaml`            | Master cleanup sequence across all environments                        |
| `ansible.log`             | Centralized execution log                                              |

---

## 🔧 Prerequisites

### For Ansible Tower Integration

1. **Tower/AWX Setup**
   - Ensure credentials are configured for target environments
   - Set up inventory sources pointing to NSX-T/vCenter
   - Configure job templates for each playbook
   - Set up notification templates for deployment status

2. **NSX-T Integration**
   - API access to NSX-T Manager
   - Proper tag structure on VMs for grouping
   - Network connectivity between Tower and NSX-T managed VMs

## 🧰 Dynamic Inventory Plugins for Enterprise Environments

- **[VMware – community.vmware](https://galaxy.ansible.com/ui/repo/published/community/vmware/)**  
  For orchestrating vSphere/ESXi environments with NSX-T and using dynamic inventory via `vmware_vm_inventory`.

- **[Community General – community.general](https://galaxy.ansible.com/ui/repo/published/community/general/)**  
  A catch-all collection for many infrastructure plugins, including NSX-T related modules.

- **[Azure – azcollection](https://galaxy.ansible.com/ui/repo/published/azure/azcollection/)** *(If using hybrid cloud)*  
  For managing Azure infrastructure with the `azure_rm` inventory plugin.

- **[AWS – amazon.aws](https://galaxy.ansible.com/ui/repo/published/amazon/aws/)** *(If using hybrid cloud)*  
  Supports dynamic inventory using the `aws_ec2` plugin.

- **[Red Hat – redhat.rhel_system_roles](https://galaxy.ansible.com/ui/repo/published/redhat/rhel_system_roles/)**  
  For managing RHEL systems in virtualized environments using predefined system roles.

## ⚙️ Step 2: Install Ansible 2.16  ====> 📘 **[Install Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)**

> **⚠️ Please Note:**  
> If you have **SELinux** enabled on remote nodes, you will also want to install **`libselinux-python`** on them **before using any `copy`/`file`/`template`-related functions in Ansible**.

### 2.1 Install Ansible Core and Collections

```bash
# Upgrade pip first
pip3 install --upgrade pip

# Install Ansible 2.16 (latest stable)
pip3 install ansible-core==2.16.12
pip3 install ansible==9.12.0

# Verify installation
ansible --version
```
---

📚 **Related References:**

- [RHEL/CentOS libselinux-python Package Info](https://centos.pkgs.org/7/centos-x86_64/libselinux-python-2.5-15.el7.x86_64.rpm.html)  
- [How to Manage SELinux in Ansible (Red Hat Guide)](https://access.redhat.com/solutions/2317631)


### 2.2 Install Essential Python Dependencies

```bash
# Core dependencies
pip3 install paramiko requests PyYAML jinja2 cryptography

# JSON/XML processing
pip3 install xmltodict pycparser

# Verify core installation
python3 -c "import ansible; print(f'Ansible version: {ansible.__version__}')"
```

## ☁️ Step 3: VMware/NSX-T Integration Setup

### 3.1 Install VMware Python SDK for NSX-T Integration

```bash
# Core VMware packages for NSX-T and vCenter
pip3 install pyvmomi==8.0.1.0
pip3 install vsphere-automation-sdk==8.0.1.0
pip3 install vapi-client-bindings==4.0.0

# Additional dependencies for API interactions
pip3 install requests-toolbelt==1.0.0
pip3 install urllib3==2.0.7
```

### 3.2 Install VMware Ansible Collection

```bash
# Install VMware collection for NSX-T integration
ansible-galaxy collection install community.vmware:==4.0.0

# Verify installation
ansible-galaxy collection list | grep vmware
```

### 3.3 Install WinRM Dependencies for Windows VM Management ====> 📘 **[Ansible Windows Guide](https://docs.ansible.com/ansible/latest/os_guide/windows_winrm.html#windows-winrm)**

```bash
# Core WinRM libraries (Required for Windows VM management)
pip3 install pywinrm==0.4.3
pip3 install requests-ntlm==1.2.0
pip3 install xmltodict==0.13.0
```

### 3.4 Configure NSX-T Dynamic Inventory

Create a dynamic inventory configuration for NSX-T:

```yaml
# inventory/nsxt_inventory.yaml
plugin: community.vmware.vmware_vm_inventory
strict: False
hostname: vcenter.example.com
username: administrator@vsphere.local
password: "{{ vault_vcenter_password }}"
validate_certs: False
with_tags: True
properties:
  - name
  - guest.ipAddress
  - config.annotation
  - summary.runtime.powerState
  - guest.guestId
  - config.hardware.numCPU
  - config.hardware.memoryMB
```

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

> **Important for Windows:**
> - Ensure the `.exe` installer is correct and compatible
> - Ensure the VM can resolve and connect to `cloudlens_manager_ip_or_FQDN`
> - Use `ssl_verify: "no"` if using IP or a self-signed cert

---

## 🏗️ Ansible Tower Configuration

### Setting Up Job Templates

1. **Create Inventory Source**
   - Type: VMware vCenter
   - Source Variables: Include NSX-T tag filtering
   - Update on Launch: Yes

2. **Create Job Templates**
   ```yaml
   # Example Job Template Configuration
   Name: Deploy CloudLens - Ubuntu
   Inventory: NSX-T Dynamic Inventory
   Project: CloudLens Deployment
   Playbook: playbooks/ubuntu.yaml
   Credentials: 
     - SSH Credential
     - Vault Credential
   Extra Variables:
     cloudlens_version: "{{ survey_cloudlens_version }}"
   ```

3. **Configure Surveys** for parameterized deployments
   - CloudLens version selection
   - Environment targeting (dev/staging/prod)
   - Registry selection

## Connectivity test and Deployment Commands

### For Tower/AWX Users

Use the Tower UI to:
1. Launch job templates for deployment
2. Monitor real-time job output
3. Schedule recurring deployments
4. Set up workflow templates for multi-stage deployments

### For CLI Users

## see host mapping
```bash
ansible-inventory -i inventory/nsxt_inventory.yaml --list | jq
```

---

## 📦 Unified Deployment & Cleanup Playbooks

To simplify execution across all environments, two master playbooks are provided:

---

### ✅ `deploy.yaml` – Unified Deployment

```bash
ansible-playbook -i inventory/ deploy.yaml
```

### For unified cleanup:

```bash
ansible-playbook -i inventory/ cleanup.yaml
```

# For specific playbooks use below: 

### Ubuntu Linux Deployment
```bash
ansible ubuntu_prod_vms -i inventory/ -m ping #test connections to ubuntu vms

ansible-playbook -i inventory/ playbooks/ubuntu.yaml   #deploy
```

### RHEL/CentOS Deployment
```bash
ansible redhat_prod_vms -i inventory/ -m ping  #test connection

ansible-playbook -i inventory/ playbooks/redhat.yaml   #deploy
```

### Windows Deployment
```bash
ansible windows_prod_vms -i inventory/ -m win_ping #test connection

ansible-playbook -i inventory/ playbooks/windows.yaml   #deploy
```

### Cleanup Commands
```bash
# Ubuntu
ansible-playbook -i inventory/ playbooks/ubuntu_cleanup.yaml 

# RHEL/CentOS
ansible-playbook -i inventory/ playbooks/redhat_cleanup.yaml 

# Windows
ansible-playbook -i inventory/ playbooks/windows_cleanup.yaml 
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

### 🗼 Tower Integration
When using Ansible Tower, logs are also available in:
- Tower Job Output UI
- Tower Database (for historical analysis)
- Exported via Tower API for external logging systems

--

## Useful Commands

- Dry run:
```bash
ansible-playbook -i inventory.ini playbook.yaml --syntax-check
```

- Set interpreter explicitly:
```ini
[all:vars]
ansible_python_interpreter=/usr/bin/python3
```

- More info: [Interpreter Discovery Guide](https://docs.ansible.com/ansible-core/2.18/reference_appendices/interpreter_discovery.html)

---

## Known Issues and Fixes

### RHEL Compatibility Issues

> **⚠️ RHEL Version Compatibility Warning:**  
> **Ansible 2.18** has known compatibility issues with **RHEL 7/8** due to Python version requirements and dependency conflicts. **Ansible 2.16** is the recommended stable version for RHEL environments.

[Ansible-core 2.16 Porting Guide — Ansible Community Documentation](https://docs.ansible.com/ansible/latest/porting_guides/porting_guide_core_2.16.html)

#### RHEL 7 Issues with Ansible 2.18:
- **Python 3.6 incompatibility** - Ansible 2.18 requires Python 3.8+
- **Collection dependency conflicts** with older package versions
- **SELinux policy issues** with newer Ansible modules

#### RHEL 8/9 Recommended Approach:
- Use **Ansible 2.16** for maximum compatibility
- Install via **EPEL repositories** for tested packages
- Use **Python 3.9+** when available

### NSX-T Specific Issues

- **Tag synchronization delays:**
> NSX-T tags may take 30-60 seconds to propagate. Consider adding wait tasks or retry logic.

- **API rate limiting:**
> Large environments may hit NSX-T API limits. Use Tower's throttling features.

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

## 🎯 Best Practices for NSX-T Environments

1. **Use NSX-T Security Tags** for dynamic grouping:
   - `Environment`: dev/staging/prod
   - `OS`: ubuntu/rhel/windows
   - `CloudLens`: enabled/disabled

2. **Leverage Tower Workflows** for:
   - Pre-deployment validation
   - Staged rollouts by environment
   - Post-deployment health checks

3. **Monitor via Tower Dashboard**:
   - Job success rates
   - Deployment times
   - Failed host patterns

---

## Contact

Please raise issues or PRs to suggest improvements or fixes.

--

# Note

You should install pywinrm on your Host because:

🔧 **Ansible Always Runs from the Control Node (Your PC/Tower)**
Ansible is agentless — it connects remotely to Windows (via WinRM) or Linux (via SSH).

So, all required Ansible Python packages (including pywinrm) must be installed on the machine where you're running Ansible — which is your PC or Ansible Tower server.

The Windows VMs just need to have WinRM enabled and reachable.

```bash
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
```
