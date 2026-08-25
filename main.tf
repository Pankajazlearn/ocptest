locals {
  name = "${var.prefix}-cluster"
  vm_names = [
    for i in range(var.vm_count) : "${var.prefix}-master-${i + 1}"
  ]
}

resource "azurerm_resource_group" "openshift" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "openshift" {
  name                = "${local.name}-vnet"
  address_space       = [var.vnet_address_space]
  location            = azurerm_resource_group.openshift.location
  resource_group_name = azurerm_resource_group.openshift.name
  tags                = var.tags
}

resource "azurerm_subnet" "openshift" {
  name                 = "${local.name}-subnet"
  resource_group_name  = azurerm_resource_group.openshift.name
  virtual_network_name = azurerm_virtual_network.openshift.name
  address_prefixes     = [var.subnet_address_prefix]
}

resource "azurerm_network_security_group" "openshift" {
  name                = "${local.name}-nsg"
  location            = azurerm_resource_group.openshift.location
  resource_group_name = azurerm_resource_group.openshift.name
  tags                = var.tags
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
  network_security_group_name = azurerm_network_security_group.openshift.name
  resource_group_name         = azurerm_resource_group.openshift.name
}

resource "azurerm_network_security_rule" "https" {
  name                        = "HTTPS"
  priority                    = 1002
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.openshift.name
  resource_group_name         = azurerm_resource_group.openshift.name
}

resource "azurerm_network_security_rule" "api_server" {
  name                        = "APIServer"
  priority                    = 1003
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "6443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.openshift.name
  resource_group_name         = azurerm_resource_group.openshift.name
}

resource "azurerm_network_security_rule" "machine_config" {
  name                        = "MachineConfigServer"
  priority                    = 1004
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22623"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.openshift.name
  resource_group_name         = azurerm_resource_group.openshift.name
}

resource "azurerm_network_security_rule" "http" {
  name                        = "HTTP"
  priority                    = 1005
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.openshift.name
  resource_group_name         = azurerm_resource_group.openshift.name
}

resource "azurerm_network_security_rule" "internal_traffic" {
  name                        = "InternalTraffic"
  priority                    = 1006
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = var.subnet_address_prefix
  destination_address_prefix  = var.subnet_address_prefix
  network_security_group_name = azurerm_network_security_group.openshift.name
  resource_group_name         = azurerm_resource_group.openshift.name
}

resource "azurerm_public_ip" "openshift" {
  count               = var.vm_count
  name                = "${local.vm_names[count.index]}-pip"
  location            = azurerm_resource_group.openshift.location
  resource_group_name = azurerm_resource_group.openshift.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_interface" "openshift" {
  count               = var.vm_count
  name                = "${local.vm_names[count.index]}-nic"
  location            = azurerm_resource_group.openshift.location
  resource_group_name = azurerm_resource_group.openshift.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.openshift.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.openshift[count.index].id
  }
}

resource "azurerm_network_interface_security_group_association" "openshift" {
  count                     = var.vm_count
  network_interface_id      = azurerm_network_interface.openshift[count.index].id
  network_security_group_id = azurerm_network_security_group.openshift.id
}

resource "azurerm_availability_set" "openshift" {
  name                        = "${local.name}-availset"
  location                    = azurerm_resource_group.openshift.location
  resource_group_name         = azurerm_resource_group.openshift.name
  platform_fault_domain_count = 2
  platform_update_domain_count = 5
  managed                     = true
  tags                        = var.tags
}

resource "azurerm_storage_account" "boot_diagnostics" {
  name                     = "diag${random_string.storage_suffix.result}"
  location                 = azurerm_resource_group.openshift.location
  resource_group_name      = azurerm_resource_group.openshift.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

resource "random_string" "storage_suffix" {
  length  = 8
  upper   = false
  special = false
}

resource "azurerm_managed_disk" "data" {
  count                = var.vm_count
  name                 = "${local.vm_names[count.index]}-data-disk"
  location             = azurerm_resource_group.openshift.location
  resource_group_name  = azurerm_resource_group.openshift.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size_gb
  tags                 = var.tags
}

resource "azurerm_linux_virtual_machine" "openshift" {
  count               = var.vm_count
  name                = local.vm_names[count.index]
  resource_group_name = azurerm_resource_group.openshift.name
  location            = azurerm_resource_group.openshift.location
  size                = var.vm_size
  admin_username           = var.admin_username
  admin_password           = var.admin_password
  disable_password_authentication = false
  availability_set_id      = azurerm_availability_set.openshift.id
  tags                = var.tags

  network_interface_ids = [
    azurerm_network_interface.openshift[count.index].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = var.disk_size_gb
  }

  source_image_reference {
    publisher = var.os_publisher
    offer     = var.os_offer
    sku       = var.os_sku
    version   = var.os_version
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.boot_diagnostics.primary_blob_endpoint
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    # Update system
    dnf update -y
    
    # Install required packages for OpenShift
    dnf install -y podman \
      buildah \
      skopeo \
      python3 \
      jq \
      wget \
      curl \
      bind-utils \
      bash-completion \
      bash-completion-extras \
      conntrack \
      device-mapper \
      ebtables \
      ethtool \
      iproute \
      iptables \
      socat \
      sysstat \
      systemd-udev-settle \
      tree \
      util-linux \
      which

    # Enable required services
    systemctl enable --now firewalld
    
    # Configure firewall rules for OpenShift
    firewall-cmd --permanent --add-port=6443/tcp    # Kubernetes API server
    firewall-cmd --permanent --add-port=22623/tcp   # Machine config server
    firewall-cmd --permanent --add-port=22624/tcp   # Machine config server
    firewall-cmd --permanent --add-port=80/tcp      # HTTP
    firewall-cmd --permanent --add-port=443/tcp     # HTTPS
    firewall-cmd --permanent --add-port=5353/udp    # mDNS
    firewall-cmd --permanent --add-port=5353/tcp    # mDNS
    firewall-cmd --permanent --add-port=4789/udp    # VXLAN
    firewall-cmd --permanent --add-port=6081/udp    # Geneve
    firewall-cmd --permanent --add-port=9000-9999/tcp  # Host-level services
    firewall-cmd --permanent --add-port=10250/tcp   # Kubelet health check
    firewall-cmd --permanent --add-port=30000-32767/tcp  # NodePort services
    firewall-cmd --permanent --add-port=9000-9999/udp  # Host-level services
    firewall-cmd --permanent --add-port=30000-32767/udp  # NodePort services
    firewall-cmd --reload
    
    # Configure kernel parameters for OpenShift
    cat >> /etc/sysctl.d/99-openshift.conf <<SYSCTL
    net.ipv4.ip_forward = 1
    net.bridge.bridge-nf-call-iptables = 1
    net.bridge.bridge-nf-call-ip6tables = 1
    fs.inotify.max_user_watches = 1048576
    fs.inotify.max_user_instances = 8192
    SYSCTL
    sysctl --system
    
    # Enable required kernel modules
    modprobe overlay
    modprobe br_netfilter
    echo "overlay" > /etc/modules-load.d/overlay.conf
    echo "br_netfilter" > /etc/modules-load.d/br_netfilter.conf
    
    # Configure container runtime (CRI-O)
    dnf install -y cri-o
    systemctl enable --now crio
    
    # Install kubectl
    curl -LO "https://dl.k8s.io/release/stable/bin/linux/amd64/kubectl"
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    
    # Install butane for OpenShift machine configs
    curl -sL https://github.com/coreos/butane/releases/latest/download/$(uname)-$(uname -m) -o /usr/local/bin/butane
    chmod +x /usr/local/bin/butane
    
    echo "OpenShift prerequisites installed successfully" > /var/log/openshift-setup.log
  EOF
  )
}

resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  count              = var.vm_count
  managed_disk_id    = azurerm_managed_disk.data[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.openshift[count.index].id
  lun                = 0
  caching            = "ReadWrite"
}
