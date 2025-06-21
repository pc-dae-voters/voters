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
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  db_name              = var.db_name
  username             = var.db_username
  password             = random_password.password.result
  parameter_group_name = "default.postgres15"
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.default.name
  publicly_accessible  = true
  tags                 = var.tags
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-="
}