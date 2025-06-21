variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "pc-dae-voters-rg"
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "uksouth"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Development"
    Project     = "PC-DAE-Voters"
  }
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
  default     = "pc-dae-voters-vnet"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_prefixes" {
  description = "Address prefixes for the subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "subnet_names" {
  description = "Names of the subnets"
  type        = list(string)
  default     = ["app", "db", "bastion"]
}

variable "db_server_name" {
  description = "Name of the PostgreSQL server"
  type        = string
  default     = "pc-dae-voters-db"
}

variable "db_name" {
  description = "Name of the PostgreSQL database"
  type        = string
  default     = "voters"
}

variable "db_admin_username" {
  description = "Admin username for the PostgreSQL server"
  type        = string
  default     = "voters_admin"
}

variable "key_vault_id" {
  description = "ID of the Key Vault to store database credentials"
  type        = string
} 