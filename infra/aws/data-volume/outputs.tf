output "volume_id" {
  description = "The ID of the EBS volume"
  value       = aws_ebs_volume.data.id
}

output "volume_arn" {
  description = "The ARN of the EBS volume"
  value       = aws_ebs_volume.data.arn
}

output "availability_zone" {
  description = "The availability zone of the EBS volume"
  value       = aws_ebs_volume.data.availability_zone
} 