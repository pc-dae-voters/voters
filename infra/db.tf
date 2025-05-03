resource "aws_db_instance" "default" {
  allocated_storage    = 20
  storage_type        = "gp2"
  engine               = "postgres"
  engine_version      = "15.4" # latest version as of Oct 26 2024
  instance_class      = "db.t3.micro" # Example instance class, adjust as needed
  name                = "voters" # database name
  username            = "voter-admin" # replace with a secure username
  password            = random_password.password.result
  parameter_group_name = "default.postgres15"
  skip_final_snapshot = true
}


# Example usage of random password generation with Terraform
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-="
}

# And then reference it:
# password = random_password.password.result