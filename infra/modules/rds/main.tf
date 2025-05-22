resource "aws_db_subnet_group" "main" {
  name       = "db-subnet-group"
  subnet_ids = var.private_subnet_ids
  tags = merge({
    Name = "db-subnet-group"
  }, var.tags)
}

resource "aws_security_group" "rds" {
  name_prefix = "rds-sg-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Be sure to restrict this in production!
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({
    Name = "rds-security-group"
  }, var.tags)
}

resource "aws_db_instance" "main" {
  identifier           = "voting-app-db"
  allocated_storage    = var.db_allocated_storage
  db_name              = var.db_name
  engine               = "postgres"
  instance_class       = var.db_instance_class
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.postgres15" # Or a more specific group
}