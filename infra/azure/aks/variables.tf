variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "voters-aks-cluster"
}

variable "kubernetes_version" {
  description = "Version of Kubernetes to use for the AKS cluster"
  type        = string
  default     = "1.31.11"
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "Size of the virtual machines in the default node pool"
  type        = string
  default     = "Standard_B2s"
}

variable "subnet_id" {
  description = "ID of the subnet where the AKS nodes will be deployed"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}
