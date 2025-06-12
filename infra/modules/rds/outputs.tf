output "db_instance_endpoint" {
  description = "The connection endpoint for the database instance."
  value       = aws_db_instance.default.endpoint
}

output "db_instance_arn" {
  description = "The ARN of the database instance."
  value       = aws_db_instance.default.arn
}

output "db_instance_name" {
  description = "The name of the database instance."
  value       = aws_db_instance.default.db_name
}

output "db_password" {
  description = "The password for the master user."
  value       = random_password.password.result
  sensitive   = true
} 