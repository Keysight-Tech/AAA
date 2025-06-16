# CloudLens Agent Deployment with Ansible

## Overview

This repository provides fully automated Ansible playbooks for deploying the CloudLens Agent across various platforms:

- **Linux (Ubuntu, RHEL/CentOS)** – Docker or Podman-based container deployment.
- **Windows** – `.exe` silent installation over WinRM.

The solution automates everything from installing dependencies to verifying agent health, including:
- Container engine setup (Docker or Podman).
- Registry trust and authentication.
- Agent container or installer deployment.
- Structured logging and clean-up.

---

## ⚠️ Note

This deployment framework supports scaling to thousands of servers across hybrid infrastructures using either static inventories or dynamic inventory plugins.

---

## 📈 Scaling Deployments

For large-scale infrastructure:
- Use dynamic inventories like `azure_rm`, `ec2`, or `gcp_compute`.
- Use `constructed.yaml` to group VMs dynamically based on tags.

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
| `inventory/azure_rm.yaml` | Azure dynamic inventory configuration                                  |
| `constructed.yaml`        | Build dynamic groups based on tags                                     |
| `ansible.cfg`             | Ansible config including SSH key path, logging, etc.                  |
| `deploy.yaml`             | Master deployment sequence across all environments                    |
| `ansible.log`             | Centralized execution log                                              |

---

## 🔧 Prerequisites



## 🧰 CLI Installation Links for Major Cloud Providers

- **[Install Azure CLI (All Platforms)](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)**
- **[Install AWS CLI (All Platforms)](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)**
- **[Install Google Cloud SDK (gcloud CLI)](https://cloud.google.com/sdk/docs/install)**
- **[Install Oracle Cloud CLI (OCI CLI)](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm)**
- **[Install IBM Cloud CLI](https://cloud.ibm.com/docs/cli?topic=cli-install-ibmcloud-cli)**
- **[Install Alibaba Cloud CLI](https://www.alibabacloud.com/help/en/developer-reference/install-the-alibaba-cloud-cli)**
- **[Install OpenStack CLI (Python OpenStackClient)](https://docs.openstack.org/python-openstackclient/latest/install/index.html)**
- **[Install VMware vSphere CLI](https://developer.vmware.com/docs/11758/vsphere-cli-7-0-u3c)**



## ⚙️ Step 2: Install Ansible 2.16  ====> 📘 **[Install Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)**

> **⚠️ Please Note:**  
> If you have **SELinux** enabled on remote nodes, you will also want to install **`libselinux-python`** on them **before using any `copy`/`file`/`template`-related functions in Ansible**.

### 2.1 Install Ansible Core and Collections

```bash
# Upgrade pip first
pip3 install --upgrade pip
``` 
# Install Ansible 2.16 (latest stable)
```
pip3 install ansible-core==2.16.12
pip3 install ansible==9.12.0
```

# Verify installation
```
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
```

# JSON/XML processing
```
pip3 install xmltodict pycparser
```

# Verify core installation
```
python3 -c "import ansible; print(f'Ansible version: {ansible.__version__}')"

``` 

## ☁️ Step 3: Azure Integration Setup

### 3.1 Install Azure CLI for any mac/windows/ubuntu/redhat etc ====> 📘 **[Azure CLI Documentation](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)**

### 3.2 Install Azure Python SDK (Compatible Versions) ====> 📘 **[Azure SDK for Python](https://docs.microsoft.com/en-us/azure/developer/python/)**

```bash
# Core Azure packages (Compatible versions for Ansible 2.16)
pip3 install azure-identity==1.15.0
pip3 install azure-mgmt-compute==30.4.0
pip3 install azure-mgmt-network==25.2.0
pip3 install azure-mgmt-resource==23.0.1
pip3 install azure-mgmt-core==1.4.0
pip3 install azure-common==1.1.28
pip3 install azure-core==1.30.0
pip3 install msrestazure==0.6.4
```
# Additional Azure services (optional)
pip3 install azure-mgmt-storage==21.0.0
pip3 install azure-mgmt-keyvault==10.2.3

### 3.3 Install WinRM Dependencies for Windows VM Management ====> 📘 **[Ansible Windows Guide](https://docs.ansible.com/ansible/latest/os_guide/windows_winrm.html#windows-winrm)**

```bash
# Core WinRM libraries (Required for Windows VM management)
pip3 install pywinrm==0.4.3
pip3 install requests-ntlm==1.2.0
pip3 install xmltodict==0.13.0
```

### 3.3 Install Azure Ansible Collection ====> 📘 **[Azure Collection Documentation](https://docs.ansible.com/ansible/latest/collections/azure/azcollection/)**


# Install compatible Azure collection
```
ansible-galaxy collection install azure.azcollection:==2.3.0
```

# Verify installation
```
ansible-galaxy collection list | grep azure
```

## Depending on your Target ENV (AWS, Azure, GCP, etc), install Ansible Galaxy collections for dynamic inventory and resource automation

- **[Azure – azcollection](https://galaxy.ansible.com/ui/repo/published/azure/azcollection/)**  
  For managing Azure infrastructure with the `azure_rm` inventory plugin and Azure modules.

- **[AWS – amazon.aws](https://galaxy.ansible.com/ui/repo/published/amazon/aws/)**  
  Supports dynamic inventory using the `aws_ec2` plugin and AWS resource automation.

- **[GCP – google.cloud](https://galaxy.ansible.com/ui/repo/published/google/cloud/)**  
  Integrates with GCP using the `gcp_compute` inventory plugin and GCP modules.

- **[VMware – community.vmware](https://galaxy.ansible.com/ui/repo/published/community/vmware/)**  
  For orchestrating vSphere/ESXi environments and using dynamic inventory via `vmware_vm_inventory`.

- **[OpenStack – openstack.cloud](https://galaxy.ansible.com/ui/repo/published/openstack/cloud/)**  
  Enables provisioning and dynamic inventory of OpenStack workloads.

- **[Kubernetes – kubernetes.core](https://galaxy.ansible.com/ui/repo/published/kubernetes/core/)**  
  Manages Kubernetes resources and supports dynamic inventory for clusters.

- **[Red Hat – redhat.rhel_system_roles](https://galaxy.ansible.com/ui/repo/published/redhat/rhel_system_roles/)**  
  For managing RHEL systems in cloud or hybrid environments using predefined system roles.

- **[Community General – community.general](https://galaxy.ansible.com/ui/repo/published/community/general/)**  
  A catch-all collection for many infrastructure plugins, including legacy inventory methods.

- **[OCI (Oracle Cloud) – oracle.oci](https://galaxy.ansible.com/ui/repo/published/oracle/oci/)**  
  For Oracle Cloud Infrastructure automation and dynamic inventory.

- **[IBM Cloud – ibm.cloudcollection](https://galaxy.ansible.com/ui/repo/published/ibm/cloudcollection/)**  
  For interacting with IBM Cloud services.

- **[Alibaba Cloud – alibaba.cloud](https://galaxy.ansible.com/ui/repo/published/alibaba/cloud/)**  
  Supports Alibaba Cloud automation and inventory.

  ```

### ✅ Install Azure Identity SDK

```
pip install azure-identity
```

# confirm identity
```
python3 -c "from azure.identity import AzureCliCredential; print(AzureCliCredential().get_token('https://management.azure.com/.default'))"
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
history
> **Important for Windows:**
> - Ensure the `.exe` installer is correct and compatible
> - Ensure the VM can resolve and connect to `cloudlens_manager_ip_or_FQDN`
> - Use `ssl_verify: "no"` if using IP or a self-signed cert

---


## Connectivity test and Deployment Commands

## see host mapping
```
ansible-inventory -i inventory/azure_rm.yaml --list | jq  
```
### Ubuntu Linux Deployment
```bash

ansible ubuntu_prod_vms -i inventory/ -m ping #test connections to ubuntu vms

ansible-playbook -i inventory/ playbooks/ubuntu.yaml   #deploy
```

### RHEL/CentOS Deployment
```bash

ansible all -i inventory/azure_rm.yaml -m ping  #test connection

ansible-playbook -i inventory/ playbooks/redhat.yaml   #deploy
```

### Windows Deployment
```bash

ansible windows_prod_vms -i inventory/ -m win_ping #test connection

ansible-playbook -i inventory/ playbooks/windows.yaml   #deploy
```

### Cleanup - Ubuntu
```bash
ansible-playbook -i inventory/ playbooks/ubuntu_cleanup.yaml 
```
### Cleanup - RHEL/CentOS
```bash
ansible-playbook -i inventory/ playbooks/redhat_cleanup.yaml 
```
### Cleanup - Windows
```bash
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

# Note

You should install pywinrm on your Host because:

🔧 **Ansible Always Runs from the Control Node (Your PC)**
Ansible is agentless — it connects remotely to Windows (via WinRM) or Linux (via SSH).

So, all required Ansible Python packages (including pywinrm) must be installed on the machine where you're running Ansible — which is your PC.

The Windows VMs just need to have WinRM enabled and reachable.

```bash
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES


