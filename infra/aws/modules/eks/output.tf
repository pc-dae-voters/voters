output "cluster_name" {
  value       = aws_eks_cluster.main.name
  description = "The name of the EKS cluster"
}

output "cluster_endpoint" {
  value       = aws_eks_cluster.main.endpoint
  description = "The endpoint for the EKS cluster"
}

output "cluster_kubeconfig" {
  value       = aws_eks_cluster.main.kubeconfig.0.value
  description = "The kubeconfig for the EKS cluster"
  sensitive   = true
}
