resource "aws_db_subnet_group" "default" {
  name       = "${var.db_name}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(
    {
      Name = "${var.db_name} DB Subnet Group"
    },
    var.tags
  )
}

resource "aws_db_instance" "default" {
  allocated_storage    = 20
  storage_type         = "gp3"
  engine               = "postgres"
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  db_name              = var.db_name
  username             = var.db_username
  password             = random_password.password.result
  parameter_group_name = "default.postgres${split(".", var.engine_version)[0]}"
  skip_final_snapshot  = true
  # The minor version is chosen by RDS, and upgraded in the maintenance window
  auto_minor_version_upgrade = true
  db_subnet_group_name = aws_db_subnet_group.default.name
  vpc_security_group_ids = var.vpc_security_group_ids
  publicly_accessible  = var.publicly_accessible
  tags                 = var.tags
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-="
}