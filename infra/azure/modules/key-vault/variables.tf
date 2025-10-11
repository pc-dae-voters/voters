variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

variable "key_vault_name" {
  description = "Name of the Key Vault"
  type        = string
  default     = "voters-key-vault"
}

variable "tenant_id" {
  description = "The Tenant ID of the Azure subscription"
  type        = string
}

variable "spn_object_id" {
  description = "The Object ID of the Service Principal"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}
