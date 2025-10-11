variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

variable "disk_name" {
  description = "Name of the managed disk"
  type        = string
  default     = "voters-data-disk"
}

variable "disk_size_gb" {
  description = "Size of the data disk in GB"
  type        = number
  default     = 100
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}
