output "instance_id" {
  description = "The ID of the data loader instance"
  value       = aws_instance.data_loader.id
}

output "public_ip" {
  description = "The public IP address of the data loader instance"
  value       = aws_instance.data_loader.public_ip
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i loader.key ec2-user@${aws_instance.data_loader.public_ip}"
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