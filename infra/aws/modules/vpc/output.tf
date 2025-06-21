output "vpc_id" {
  value       = aws_vpc.main.id
  description = "The ID of the VPC"
}

output "public_subnet_ids" {
  value       = [for subnet in aws_subnet.public : subnet.id]
  description = "List of IDs of public subnets"
}

output "private_subnet_ids" {
  value       = [for subnet in aws_subnet.private : subnet.id]
  description = "List of IDs of private subnets"
}

output "availability_zones" {
  value       = var.availability_zones
  description = "List of Availability Zones"
}

output "default_security_group_id" {
  value       = aws_vpc.main.default_security_group_id
  description = "The ID of the default security group"
}
