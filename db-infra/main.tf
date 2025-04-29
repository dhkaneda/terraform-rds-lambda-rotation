resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}


resource "aws_security_group" "postgres_public" {
  name        = "postgres_public"
  description = "Allow inbound traffic to Postgres from public"
  vpc_id      = aws_default_vpc.default.id

  tags = {
    Name = "postgres_public"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_postgres_public" {
  security_group_id = aws_security_group.postgres_public.id
  ip_protocol       = "tcp"
  from_port         = 5432
  to_port           = 5432
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.postgres_public.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

data "aws_db_subnet_group" "default_subnet_group" {
  name = "default-${aws_default_vpc.default.id}"
}

output "default_subnet_group_name" {
  value = data.aws_db_subnet_group.default_subnet_group.name
}

resource "aws_db_parameter_group" "custom" {
  name   = var.project_name
  family = "postgres14"

  parameter {
    name  = "log_connections"
    value = "1"
  }
}

resource "aws_db_instance" "rds" {
  identifier             = var.project_name
  instance_class         = "db.t3.micro"
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "14.12"
  username               = "postgres"
  manage_master_user_password = true
  db_subnet_group_name   = data.aws_db_subnet_group.default_subnet_group.name
  vpc_security_group_ids = [aws_security_group.postgres_public.id]
  parameter_group_name   = aws_db_parameter_group.custom.name
  publicly_accessible    = true
  skip_final_snapshot    = true
}
