variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-openshift-cluster"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "openshift"
}

variable "vm_count" {
  description = "Number of VMs to create"
  type        = number
  default     = 3

  validation {
    condition     = var.vm_count >= 1 && var.vm_count <= 10
    error_message = "VM count must be between 1 and 10."
  }
}

variable "vm_size" {
  description = "Azure VM size (must support nested virtualization for OpenShift)"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "admin_username" {
  description = "Admin username for the VMs"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Admin password for the VMs"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.admin_password) >= 12
    error_message = "Password must be at least 12 characters."
  }
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_address_prefix" {
  description = "Address prefix for the OpenShift subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "os_publisher" {
  description = "OS image publisher"
  type        = string
  default     = "RedHat"
}

variable "os_offer" {
  description = "OS image offer"
  type        = string
  default     = "RHEL"
}

variable "os_sku" {
  description = "OS image SKU"
  type        = string
  default     = "8-lvm-gen2"
}

variable "os_version" {
  description = "OS image version"
  type        = string
  default     = "latest"
}

variable "disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 128
}

variable "data_disk_size_gb" {
  description = "Data disk size in GB for OpenShift persistent storage"
  type        = number
  default     = 256
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "openshift"
    ManagedBy   = "terraform"
  }
}
