output "cluster_name" {
  description = "The name of the EKS cluster."
  value       = aws_eks_cluster.voters_cluster.name
}

output "cluster_endpoint" {
  description = "The endpoint for your EKS Kubernetes API."
  value       = aws_eks_cluster.voters_cluster.endpoint
}

output "cluster_ca_certificate" {
  description = "The certificate authority data for your EKS cluster."
  value       = base64decode(aws_eks_cluster.voters_cluster.certificate_authority[0].data)
  sensitive   = true
} 