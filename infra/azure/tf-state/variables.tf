variable "resource_group_name" {
  description = "Name of the resource group for Terraform state"
  type        = string
  default     = "pc-dae-voters-tfstate"
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "uksouth"
}

variable "storage_account_name" {
  description = "Name of the storage account for Terraform state"
  type        = string
  default     = "pcdaevoterstfstate"
}

variable "container_name" {
  description = "Name of the storage container for Terraform state"
  type        = string
  default     = "tfstate"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Development"
    Project     = "PC-DAE-Voters"
    Purpose     = "Terraform State"
  }
} 