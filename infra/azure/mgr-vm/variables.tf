variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

variable "vm_name" {
  description = "Name of the manager virtual machine"
  type        = string
  default     = "voters-manager-vm"
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Admin username for the virtual machine"
  type        = string
  default     = "azureuser"
}

variable "subnet_id" {
  description = "ID of the subnet where the VM will be deployed"
  type        = string
}

variable "data_disk_id" {
  description = "ID of the managed disk to attach to the VM"
  type        = string
}

variable "db_host" {
  description = "Database host FQDN"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "cloud_init_version" {
  description = "Version of the cloud-init script to force re-execution"
  type        = string
  default     = "1.0"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}
