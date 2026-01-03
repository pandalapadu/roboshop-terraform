resource "azurerm_network_interface" "main" {
  name = "${var.component}-nic"
  location = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  ip_configuration {
    name = "internal"
    subnet_id = data.azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.main.id
  }
}
resource "azurerm_network_security_group" "main" {
  name                = "${var.component}-nsg"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  security_rule {
    name                       = "Allow-all"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}
resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

resource "azurerm_public_ip" "main" {
  name = "${var.component}-pip"
  location = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  allocation_method = "Static"
  sku = "Standard"
  ip_version = "IPv4"
}
resource "azurerm_virtual_machine" "main" {
  name                  = var.component
  location              = data.azurerm_resource_group.main.location
  resource_group_name   = data.azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_D2s_v3"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "94_gen2"
    version   = "9.4.2025040316" #exact version from az vm show
  }
  storage_os_disk {
    name              = var.component
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = var.component
    admin_username = "azureuser"
    admin_password = "azureuser@123"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    component = var.component
  }
  ###########To Connect Remote server we will use remote exec
  #   provisioner "remote-exec" {
  #     inline = [
  #       # Install Git
  #       "sudo dnf install -y git",
  #       ## Install Terraform via direct RPM
  #       "sudo dnf install -y https://rpm.releases.hashicorp.com/RHEL/9/x86_64/stable/terraform-1.8.5-1.x86_64.rpm",
  #       # Install Azure CLI
  #       "sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc && sudo dnf install -y https://packages.microsoft.com/config/rhel/9.0/packages-microsoft-prod.rpm && sudo dnf install -y azure-cli"
  #     ]
  #
  #     connection {
  #       type        = "ssh"
  #       user        = "azureuser"
  #       password    = "azureuser@123"
  #       host        = azurerm_public_ip.main.ip_address
  #     }
  #   }
}

resource "null_resource" "install_tools" {
  depends_on = [azurerm_virtual_machine.main]
  provisioner "remote-exec" {
    inline = [
      "sudo dnf install -y git",
      "sudo dnf install -y https://rpm.releases.hashicorp.com/RHEL/9/x86_64/stable/terraform-1.8.5-1.x86_64.rpm",
      "sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc && sudo dnf install -y https://packages.microsoft.com/config/rhel/9.0/packages-microsoft-prod.rpm && sudo dnf install -y azure-cli",
      "sudo dnf install -y python3.12 python3.12-pip && sudo pip3.12 install ansible",
      "sudo dnf install -y make"
    ]

    connection {
      type        = "ssh"
      user        = "azureuser"
      password    = "azureuser@123"
      host        = azurerm_public_ip.main.ip_address
    }
  }
}

##For Create an A record in DNS server
resource "azurerm_dns_a_record" "main" {
  name                = "${var.component}-dev"                       # subdomain (www.example.com)
  zone_name           = "azdevopsvenkat.site"
  resource_group_name = data.azurerm_resource_group.main.name
  ttl                 = 10                          # time-to-live in seconds
  records             = [azurerm_network_interface.main.private_ip_address]             # IP address of your VM or service
}

