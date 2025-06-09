terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.75.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "16e5b426-6372-4975-908a-e4cc44ee3cab"
}

variable "ubuntu_vm_count" {
  type    = number
  default = 1
}

variable "rhel_vm_count" {
  type    = number
  default = 1
}

variable "windows_vm_count" {
  type    = number
  default = 1
}

resource "azurerm_resource_group" "brinek_rg" {
  name     = "BrineK"
  location = "EastUS2"
}

resource "azurerm_virtual_network" "brinek_vnet" {
  name                = "brinekVNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.brinek_rg.location
  resource_group_name = azurerm_resource_group.brinek_rg.name
}

resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.brinek_rg.name
  virtual_network_name = azurerm_virtual_network.brinek_vnet.name
  address_prefixes     = ["10.0.1.0/26"]
}

resource "azurerm_subnet" "vm_subnet" {
  name                 = "brinekVMSubnet"
  resource_group_name  = azurerm_resource_group.brinek_rg.name
  virtual_network_name = azurerm_virtual_network.brinek_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "vm_nsg" {
  name                = "BrinekVMNSG"
  location            = azurerm_resource_group.brinek_rg.location
  resource_group_name = azurerm_resource_group.brinek_rg.name

  security_rule {
    name                       = "AllowSSHFromBastion"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = azurerm_subnet.bastion_subnet.address_prefixes[0]
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowRDPFromBastion"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = azurerm_subnet.bastion_subnet.address_prefixes[0]
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowWinRMFromBastion"
    priority                   = 115
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["5985", "5986"]
    source_address_prefix      = azurerm_subnet.bastion_subnet.address_prefixes[0]
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAllOutbound"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "vm_nsg_assoc" {
  subnet_id                 = azurerm_subnet.vm_subnet.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

resource "azurerm_public_ip" "bastion_public_ip" {
  name                = "BastionPublicIP"
  location            = azurerm_resource_group.brinek_rg.location
  resource_group_name = azurerm_resource_group.brinek_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  name                = "BrinekBastion"
  location            = azurerm_resource_group.brinek_rg.location
  resource_group_name = azurerm_resource_group.brinek_rg.name

  ip_configuration {
    name                 = "bastion-ip-config"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_public_ip.id
  }

  sku = "Standard"

  tunneling_enabled = true

}

resource "azurerm_network_interface" "ubuntu_nic" {
  count               = var.ubuntu_vm_count
  name                = "UbuntuNIC-${count.index}"
  location            = azurerm_resource_group.brinek_rg.location
  resource_group_name = azurerm_resource_group.brinek_rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "ubuntu_vm" {
  count                         = var.ubuntu_vm_count
  name                          = "UbuntuVM-${count.index}"
  resource_group_name           = azurerm_resource_group.brinek_rg.name
  location                      = azurerm_resource_group.brinek_rg.location
  size                          = "Standard_B1s"
  admin_username                = "brine"
  disable_password_authentication = true
  network_interface_ids         = [azurerm_network_interface.ubuntu_nic[count.index].id]

  os_disk {
    caching              = "ReadWrite"
    disk_size_gb         = 127
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "brine"
    public_key = file("/Users/brinketu/Downloads/eks-terraform-key.pub")
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    sudo apt update
    sudo apt install -y nginx
  EOF
  )

  tags = {
    Name = "UbuntuVM-${count.index}"
    Env  = "Development"
  }
}

resource "azurerm_network_interface" "rhel_nic" {
  count               = var.rhel_vm_count
  name                = "RHELNIC-${count.index}"
  location            = azurerm_resource_group.brinek_rg.location
  resource_group_name = azurerm_resource_group.brinek_rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "rhel_vm" {
  count                         = var.rhel_vm_count
  name                          = "RHELVM-${count.index}"
  resource_group_name           = azurerm_resource_group.brinek_rg.name
  location                      = azurerm_resource_group.brinek_rg.location
  size                          = "Standard_B2s"
  admin_username                = "brine"
  disable_password_authentication = true
  network_interface_ids         = [azurerm_network_interface.rhel_nic[count.index].id]

  os_disk {
    caching              = "ReadWrite"
    disk_size_gb         = 127
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "8-LVM"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "brine"
    public_key = file("/Users/brinketu/Downloads/eks-terraform-key.pub")
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install httpd -y
    sudo systemctl enable httpd
    sudo systemctl start httpd
  EOF
  )

  tags = {
    Name = "RHELVM-${count.index}"
    Env  = "Development"
  }
}

resource "azurerm_network_interface" "windows_nic" {
  count               = var.windows_vm_count
  name                = "WindowsNIC-${count.index}"
  location            = azurerm_resource_group.brinek_rg.location
  resource_group_name = azurerm_resource_group.brinek_rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "windows_vm" {
  count                         = var.windows_vm_count
  name                          = "WindowsVM-${count.index}"
  resource_group_name           = azurerm_resource_group.brinek_rg.name
  location                      = azurerm_resource_group.brinek_rg.location
  size                          = "Standard_B2s"
  admin_username                = "brine"
  admin_password                = "Bravedemo123."
  network_interface_ids         = [azurerm_network_interface.windows_nic[count.index].id]

  os_disk {
    caching              = "ReadWrite"
    disk_size_gb         = 127
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  provision_vm_agent       = true
  enable_automatic_updates = true

  custom_data = base64encode(<<-EOF
    Set-ItemProperty -Path 'HKLM:\\System\\CurrentControlSet\\Control\\Terminal Server' -Name "fDenyTSConnections" -Value 0
    Get-NetFirewallRule -DisplayGroup "Remote Desktop" | Enable-NetFirewallRule
    Set-Service -Name TermService -StartupType Automatic
    Start-Service TermService
    Set-ItemProperty -Path 'HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Terminal Server\\WinStations\\RDP-Tcp' -Name 'UserAuthentication' -Value 0
    Set-NetConnectionProfile -InterfaceAlias "Ethernet" -NetworkCategory Private
  EOF
  )

  tags = {
    Name = "WindowsVM-${count.index}"
    Env  = "Development"
  }
}

resource "azurerm_virtual_machine_extension" "winrm_config" {
  count                = var.windows_vm_count
  name                 = "winrm-config-extension-${count.index}"
  virtual_machine_id   = azurerm_windows_virtual_machine.windows_vm[count.index].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
{}
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
{
  "fileUris": [
    "https://raw.githubusercontent.com/ansible/ansible/stable-2.9/examples/scripts/ConfigureRemotingForAnsible.ps1"
  ],
  "commandToExecute": "powershell -ExecutionPolicy Unrestricted -File ConfigureRemotingForAnsible.ps1"
}
PROTECTED_SETTINGS

  depends_on = [azurerm_windows_virtual_machine.windows_vm]
}

output "bastion_public_ip" {
  description = "Public IP address for Azure Bastion Host"
  value       = azurerm_public_ip.bastion_public_ip.ip_address
}

output "ubuntu_private_ips" {
  description = "Private IP addresses of Ubuntu VMs"
  value       = [for nic in azurerm_network_interface.ubuntu_nic : nic.private_ip_address]
}

output "rhel_private_ips" {
  description = "Private IP addresses of RHEL VMs"
  value       = [for nic in azurerm_network_interface.rhel_nic : nic.private_ip_address]
}

output "windows_private_ips" {
  description = "Private IP addresses of Windows VMs"
  value       = [for nic in azurerm_network_interface.windows_nic : nic.private_ip_address]
}

output "ansible_inventory" {
  description = "Ansible inventory using only private IPs, with group vars for Windows"

  value = join("\n", concat(
    ["[ubuntu_vms]"],
    [for nic in azurerm_network_interface.ubuntu_nic : nic.private_ip_address],

    ["", "[redhat_vms]"],
    [for nic in azurerm_network_interface.rhel_nic : nic.private_ip_address],

    ["", "[windows]"],
    [for nic in azurerm_network_interface.windows_nic : nic.private_ip_address],

    ["", "[windows:vars]"],
    [
      "ansible_user=brine",
      "ansible_password=Bravedemo123.",
      "ansible_connection=winrm",
      "ansible_winrm_transport=ntlm",
      "ansible_winrm_server_cert_validation=ignore"
    ]
  ))
}
