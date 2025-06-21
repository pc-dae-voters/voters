output "instance_id" {
  description = "The ID of the manager instance"
  value       = aws_instance.manager.id
}

output "public_ip" {
  description = "The public IP address of the manager instance"
  value       = aws_instance.manager.public_ip
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i loader.key ec2-user@${aws_instance.manager.public_ip}"
}

output "admin_role_arn" {
  description = "The ARN of the admin role with Administrator privileges"
  value       = aws_iam_role.manager_admin_role.arn
}

output "admin_role_name" {
  description = "The name of the admin role"
  value       = aws_iam_role.manager_admin_role.name
}

output "database_connection_info" {
  description = "Database connection information"
  value = {
    host     = data.terraform_remote_state.db.outputs.db_instance_endpoint
    database = data.terraform_remote_state.db.outputs.db_name
    username = data.terraform_remote_state.db.outputs.db_username
  }
  sensitive = true
} 