output "peering_connection_id" {
  description = "ID of the VPC peering connection between the voters and EKS VPCs"
  value       = aws_vpc_peering_connection.eks.id
}

output "eks_vpc_cidr_block" {
  description = "CIDR block of the EKS cluster's VPC"
  value       = data.aws_vpc.eks.cidr_block
}
