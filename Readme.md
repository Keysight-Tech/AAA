# CloudLens Agent Deployment with Ansible

## Overview

This repository provides an Ansible playbook to deploy the CloudLens Agent across various environments, including Ubuntu virtual machines (e.g., Azure VMs, AWS EC2, on-premise servers). <light>The playbook automates Docker installation and configuration, along with the deployment of the CloudLens Agent container, supporting both secure and insecure container registries. </light>

---

## Repository Contents

- `main.yaml` - Primary Ansible playbook responsible for:
    - Installing and configuring Docker if it's not already present.
    - Configuring Docker daemon for secure or insecure private registries.
    - Deploying the CloudLens Agent container with specified settings.
- `vars.yml` - Variables file that defines customizable parameters such as:
    - Docker package names to install.
    - CloudLens Manager IP/FQDN for agent communication.
    - Registry type (`secure` or `insecure`) and paths to related certificates.
    - Project key, container names, custom tags, and logging options for the CloudLens Agent.
- `inventory.ini` - Inventory file that lists the target VM hosts, grouped for easier management (e.g., `onprem_vms`, `azure_vms`, `aws_ec2`).
- `README.md` - This comprehensive documentation file.

---

## Prerequisites

- **Ansible Control Machine:**  A machine with Ansible installed (version 2.9+ recommended). This machine will execute the playbook.
- **Target VMs:**  Target virtual machines or servers running Ubuntu or other compatible Linux distributions. Ensure they have network connectivity.
- **SSH Access:**  SSH access to the target VMs from the control machine, configured with passwordless `sudo` or appropriate privilege escalation to run Docker commands.
- **Docker-Compatible Environment:**  A Docker-compatible container runtime environment on the target VMs (Docker, Containerd, etc.).
- **Network Access:**  Network access from the target VMs to the CloudLens Manager server and the container registry where the CloudLens Agent image is stored.

---

## Setup and Configuration

### 1. Inventory File (`inventory.ini`)

Create or modify your inventory file to list the target hosts. This file groups your servers for easier management.

Dry run:  ansible-playbook -i inventory.ini main.yaml --syntax-check  

## Ansible Python Interpreter

See [Ansible Interpreter Discovery Guide](https://docs.ansible.com/ansible-core/2.18/reference_appendices/interpreter_discovery.html) for why specifying `ansible_python_interpreter` can prevent unexpected behavior.  
       Ignore warning when running playbook if using appropriate Directory for the python interpreter.
