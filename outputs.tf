output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.openshift.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.openshift.id
}

output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.openshift.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.openshift.name
}

output "subnet_id" {
  description = "ID of the OpenShift subnet"
  value       = azurerm_subnet.openshift.id
}

output "nsg_id" {
  description = "ID of the network security group"
  value       = azurerm_network_security_group.openshift.id
}

output "vm_names" {
  description = "Names of the virtual machines"
  value       = azurerm_linux_virtual_machine.openshift[*].name
}

output "vm_ids" {
  description = "IDs of the virtual machines"
  value       = azurerm_linux_virtual_machine.openshift[*].id
}

output "vm_private_ips" {
  description = "Private IP addresses of the VMs"
  value       = azurerm_network_interface.openshift[*].private_ip_address
}

output "vm_public_ips" {
  description = "Public IP addresses of the VMs"
  value       = azurerm_public_ip.openshift[*].ip_address
}

output "ssh_connection_strings" {
  description = "SSH connection strings for each VM"
  value = [
    for i, ip in azurerm_public_ip.openshift[*].ip_address :
    "ssh ${var.admin_username}@${ip}"
  ]
}

output "availability_set_id" {
  description = "ID of the availability set"
  value       = azurerm_availability_set.openshift.id
}

output "storage_account_name" {
  description = "Name of the boot diagnostics storage account"
  value       = azurerm_storage_account.boot_diagnostics.name
}
