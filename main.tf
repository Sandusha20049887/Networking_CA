resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = random_pet.rg_name.id
}

# Create virtual network
resource "azurerm_virtual_network" "my_terraform_network" {
  name                = "myVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "my_terraform_subnet" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.my_terraform_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "my_terraform_public_ip" {
  name                = "myPublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "my_terraform_nsg" {
  name                = "myNetworkSecurityGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "my_terraform_nic" {
  name                = "myNIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.my_terraform_subnet.id
    private_ip_address_allocation = "Dynamic"
    #private_ip_address            = "10.0.1.4"
    public_ip_address_id = azurerm_public_ip.my_terraform_public_ip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.my_terraform_nic.id
  network_security_group_id = azurerm_network_security_group.my_terraform_nsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "my_storage_account" {
  name                     = "diag${random_id.random_id.hex}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "my_terraform_vm" {
  name                  = "NetworkingCA"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.my_terraform_nic.id]
  size                  = "Standard_B1s"

  provisioner "remote-exec" {
    inline = [
      "wget https://raw.githubusercontent.com/Sandusha20049887/Networking_CA/main/install-docker.sh -O /tmp/install-docker.sh",
      "chmod +x /tmp/install-docker.sh",
      "/tmp/install-docker.sh",
    ]
  }
  # provisioner "file" {
  #   source      = "https://raw.githubusercontent.com/Sandusha20049887/Networking_CA/install-docker.sh"
  #   destination = "/tmp/install-docker.sh"
  # }
  # provisioner "remote-exec" {
  #   inline = [
  #     "chmod +x /tmp/install-docker.sh",
  #     "/tmp/install-docker.sh",
  #   ]
  # }
  connection {
    type     = "ssh"
    user     = var.username
    password = "Sandusha@123"
    host     = azurerm_public_ip.my_terraform_public_ip.ip_address
    #private_key = file("~/.ssh/id_ed25519")
  }

  # Path to the script file to docker intall
  #custom_data = "IyEvYmluL2Jhc2gKIyBVcGRhdGUgdGhlIHBhY2thZ2UgaW5kZXgKc3VkbyBhcHQtZ2V0IHVwZGF0ZSAteQoKIyBJbnN0YWxsIHByZXJlcXVpc2l0ZXMKc3VkbyBhcHQtZ2V0IGluc3RhbGwgLXkgYXB0LXRyYW5zcG9ydC1odHRwcyBjYS1jZXJ0aWZpY2F0ZXMgY3VybCBzb2Z0d2FyZS1wcm9wZXJ0aWVzLWNvbW1vbgoKIyBBZGQgRG9ja2Vy4oCZcyBvZmZpY2lhbCBHUEcga2V5CmN1cmwgLWZzU0wgaHR0cHM6Ly9kb3dubG9hZC5kb2NrZXIuY29tL2xpbnV4L3VidW50dS9ncGcgfCBzdWRvIGdwZyAtLWRlYXJtb3IgLW8gL3Vzci9zaGFyZS9rZXlyaW5ncy9kb2NrZXItYXJjaGl2ZS1rZXlyaW5nLmdwZwoKIyBTZXQgdXAgdGhlIERvY2tlciBzdGFibGUgcmVwb3NpdG9yeQplY2hvICJkZWIgW2FyY2g9YW1kNjQgc2lnbmVkLWJ5PS91c3Ivc2hhcmUva2V5cmluZ3MvZG9ja2VyLWFyY2hpdmUta2V5cmluZy5ncGddIGh0dHBzOi8vZG93bmxvYWQuZG9ja2VyLmNvbS9saW51eC91YnVudHUgJChsc2JfcmVsZWFzZSAtY3MpIHN0YWJsZSIgfCBzdWRvIHRlZSAvZXRjL2FwdC9zb3VyY2VzLmxpc3QuZC9kb2NrZXIubGlzdCA+IC9kZXYvbnVsbAoKIyBJbnN0YWxsIERvY2tlcgpzdWRvIGFwdC1nZXQgdXBkYXRlIC15CnN1ZG8gYXB0LWdldCBpbnN0YWxsIC15IGRvY2tlci1jZQoKIyBFbmFibGUgRG9ja2VyIHRvIHN0YXJ0IG9uIGJvb3QKc3VkbyBzeXN0ZW1jdGwgZW5hYmxlIGRvY2tlcgpzdWRvIHN5c3RlbWN0bCBzdGFydCBkb2NrZXIK"

  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name                   = "networkingca"
  admin_username                  = var.username
  admin_password                  = "Sandusha@123"
  disable_password_authentication = false

  # admin_ssh_key {
  #   username   = var.username
  #   public_key = azapi_resource_action.ssh_public_key_gen.output.publicKey
  # }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.my_storage_account.primary_blob_endpoint
  }
}


