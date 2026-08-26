provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rhel" {
  name     = "rg-rhel-vm"
  location = "uksouth"
}

resource "azurerm_virtual_network" "rhel" {
  name                = "rhel-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rhel.location
  resource_group_name = azurerm_resource_group.rhel.name
}

resource "azurerm_subnet" "rhel" {
  name                 = "rhel-subnet"
  resource_group_name  = azurerm_resource_group.rhel.name
  virtual_network_name = azurerm_virtual_network.rhel.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "rhel" {
  name                = "rhel-pip"
  location            = azurerm_resource_group.rhel.location
  resource_group_name = azurerm_resource_group.rhel.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "rhel" {
  name                = "rhel-nsg"
  location            = azurerm_resource_group.rhel.location
  resource_group_name = azurerm_resource_group.rhel.name
}

resource "azurerm_network_security_rule" "ssh" {
  name                        = "SSH"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.rhel.name
  resource_group_name         = azurerm_resource_group.rhel.name
}

resource "azurerm_network_interface" "rhel" {
  name                = "rhel-nic"
  location            = azurerm_resource_group.rhel.location
  resource_group_name = azurerm_resource_group.rhel.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.rhel.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.rhel.id
  }
}

resource "azurerm_network_interface_security_group_association" "rhel" {
  network_interface_id      = azurerm_network_interface.rhel.id
  network_security_group_id = azurerm_network_security_group.rhel.id
}

resource "azurerm_linux_virtual_machine" "rhel" {
  name                  = "rhel-vm"
  resource_group_name   = azurerm_resource_group.rhel.name
  location              = azurerm_resource_group.rhel.location
  size                  = "Standard_B2s"
  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.rhel.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa_azure.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 64
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "8-lvm-gen2"
    version   = "latest"
  }
}
