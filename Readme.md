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


## Install Ansible on Your PC ( Control Node) ====> 📘 **[Install Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)**

> **⚠️ Please Note:**  
> If you have **SELinux** enabled on remote nodes, you will also want to install **`libselinux-python`** on them **before using any `copy`/`file`/`template`-related functions in Ansible**.  
> 
> You can use the `yum` or `dnf` module in Ansible to install this package on remote systems that do not have it.

---

📚 **Related References:**

- [RHEL/CentOS libselinux-python Package Info](https://centos.pkgs.org/7/centos-x86_64/libselinux-python-2.5-15.el7.x86_64.rpm.html)  
- [How to Manage SELinux in Ansible (Red Hat Guide)](https://access.redhat.com/solutions/2317631)

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

  

### ✅ Install Azure Identity SDK

```
pip install azure-identity
```

# confirm identity

python3 -c "from azure.identity import AzureCliCredential; print(AzureCliCredential().get_token('https://management.azure.com/.default'))"


## 🧰 CLI Installation Links for Major Cloud Providers

- **[Install Azure CLI (All Platforms)](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)**
- **[Install AWS CLI (All Platforms)](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)**
- **[Install Google Cloud SDK (gcloud CLI)](https://cloud.google.com/sdk/docs/install)**
- **[Install Oracle Cloud CLI (OCI CLI)](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm)**
- **[Install IBM Cloud CLI](https://cloud.ibm.com/docs/cli?topic=cli-install-ibmcloud-cli)**
- **[Install Alibaba Cloud CLI](https://www.alibabacloud.com/help/en/developer-reference/install-the-alibaba-cloud-cli)**
- **[Install OpenStack CLI (Python OpenStackClient)](https://docs.openstack.org/python-openstackclient/latest/install/index.html)**
- **[Install VMware vSphere CLI](https://developer.vmware.com/docs/11758/vsphere-cli-7-0-u3c)**


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

### Ubuntu Linux Deployment
```bash

ansible ubuntu_prod_vms -i inventory/ -m ping #test connections to ubuntu vms

ansible-playbook -i inventory/ playbooks/ubuntu.yaml --limit ubuntu_prod_vms   #deploy
```

### RHEL/CentOS Deployment
```bash

ansible redhat_prod_vms -i inventory/ -m raw -a "echo OK"  #test connection

ansible-playbook -i inventory/ playbooks/redhat.yaml --limit redhat_prod_vms  #deploy
```

### Windows Deployment
```bash

ansible windows_prod_vms -i inventory/ -m win_ping #test connection

ansible-playbook -i inventory/ playbooks/windows.yaml --limit windows_prod_vms  #deploy
```

### Cleanup - Ubuntu
```bash
ansible-playbook -i inventory/ playbooks/ubuntu_cleanup.yaml --limit ubuntu_prod_vms  
```

### Cleanup - RHEL/CentOS
```bash
ansible-playbook -i inventory/ playbooks/redhat_cleanup.yaml --limit redhat_prod_vms  
```

### Cleanup - Windows
```bash
ansible-playbook -i inventory/ playbooks/windows_cleanup.yaml --limit windows_prod_vms  
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

# Note

You should install pywinrm on your Host because:

🔧 **Ansible Always Runs from the Control Node (Your PC)**
Ansible is agentless — it connects remotely to Windows (via WinRM) or Linux (via SSH).

So, all required Ansible Python packages (including pywinrm) must be installed on the machine where you're running Ansible — which is your PC.

The Windows VMs just need to have WinRM enabled and reachable.

```bash
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES


