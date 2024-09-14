resource "random_string" "user" {
  length  = 16
  special = false
  numeric = false
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_instance" "postgres" {
  engine                 = "postgres"
  port                   = "5432"
  allocated_storage      = var.rds_allocated_storage
  engine_version         = var.rds_engine_version
  instance_class         = var.rds_instance_class
  username               = random_string.user.result
  password               = random_password.password.result
  availability_zone      = "${var.aws_region_name}b"
  db_subnet_group_name   = var.subnet_group_name
  vpc_security_group_ids = [var.sg_id]
  publicly_accessible    = false
  skip_final_snapshot    = true
  multi_az               = false
  tags = {
    "Section"  = "data_store",
    "Resource" = "rds-instance"
  }
}