variable "name" {
  type = string
}

variable "tags" {
  type        = map(string)
  description = "Resource specific tags"
  default     = null
}

variable "force_destroy" {
  type    = bool
  default = false
}

variable "encryption_enabled" {
  type    = bool
  default = true
}

variable "block_public_access" {
  type    = bool
  default = true
}

variable "region" {
  type    = string
  default = "eu-west-1"
}
