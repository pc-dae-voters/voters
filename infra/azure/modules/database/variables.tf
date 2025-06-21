variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

variable "server_name" {
  description = "Name of the PostgreSQL server"
  type        = string
}

variable "db_name" {
  description = "Name of the PostgreSQL database"
  type        = string
}

variable "admin_username" {
  description = "Admin username for the PostgreSQL server"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet where the database will be deployed"
  type        = string
}

variable "vnet_id" {
  description = "ID of the virtual network"
  type        = string
}

variable "key_vault_id" {
  description = "ID of the Key Vault to store database credentials"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
} 