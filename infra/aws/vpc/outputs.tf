# Read by the other voters modules using terraform_remote_state

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

output "availability_zones" {
  description = "The availability zones of the subnets, in the same order"
  value       = module.vpc.availability_zones
}

output "route_table_ids" {
  description = "IDs of the VPC's route tables"
  value       = module.vpc.route_table_ids
}
