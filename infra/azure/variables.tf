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

# --- Data Volume ---
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

# --- Manager VM ---
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
  description = "Admin username for the manager VM"
  type        = string
  default     = "azureuser"
}

variable "cloud_init_version" {
  description = "A version number for the cloud-init script, used to force re-provisioning on changes."
  type        = string
  default     = "1.0.0"
}

# --- Key Vault ---
variable "key_vault_name" {
  description = "Name of the Key Vault"
  type        = string
  default     = "voters-key-vault-unique" # Needs to be globally unique
}

# --- AKS Cluster Variables ---
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