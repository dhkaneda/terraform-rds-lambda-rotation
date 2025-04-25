# resource "aws_secretsmanager_secret" "rds_master_password" {
#   name = "rds-master-password"
# }

# resource "aws_secretsmanager_secret_version" "rds_master_password_version" {
#   secret_id     = aws_secretsmanager_secret.rds_master_password.id
#   secret_string = jsonencode({
#     username = var.db_username
#     password = random_password.master_password.result
#   })
# }

# resource "random_password" "master_password" {
#   length  = 16
#   special = true
# }


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

# resource "aws_secretsmanager_secret" "rds_master_password" {
#   name = "${var.project_name}-master-password" 
# }

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


# resource "aws_subnet" "subnet_a" {
#   vpc_id            = aws_vpc.main.id
#   cidr_block        = "10.0.1.0/24"
#   availability_zone = "us-west-2a"
# }

# resource "aws_db_subnet_group" "rds_subnet_group" {
#   name       = "rds-subnet-group"
#   subnet_ids = [aws_subnet.subnet_a.id]
# }

# # Lambda IAM role and policy
# resource "aws_iam_role" "lambda_rotation" {
#   name = "lambda-rotation-role"
#   assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
# }

# data "aws_iam_policy_document" "lambda_assume_role" {
#   statement {
#     actions = ["sts:AssumeRole"]
#     principals {
#       type        = "Service"
#       identifiers = ["lambda.amazonaws.com"]
#     }
#   }
# }

# resource "aws_iam_role_policy_attachment" "lambda_basic" {
#   role       = aws_iam_role.lambda_rotation.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
# }

# # Lambda function placeholder
# resource "aws_lambda_function" "rotate_secret" {
#   function_name = "rotate-rds-secret"
#   handler       = "lambda_function.lambda_handler"
#   runtime       = "python3.11"
#   role          = aws_iam_role.lambda_rotation.arn
#   filename      = "${path.module}/lambda/rotate_secret.zip"
#   source_code_hash = filebase64sha256("${path.module}/lambda/rotate_secret.zip")
#   environment {
#     variables = {
#       SECRET_ARN = aws_secretsmanager_secret.rds_master_password.arn
#       DB_HOST    = aws_db_instance.rds.endpoint
#       DB_USER    = var.db_username
#     }
#   }
# }

# # Secrets Manager rotation configuration
# resource "aws_secretsmanager_secret_rotation" "rds_rotation" {
#   secret_id           = aws_secretsmanager_secret.rds_master_password.id
#   rotation_lambda_arn = aws_lambda_function.rotate_secret.arn
#   rotation_rules {
#     automatically_after_days = 30
#   }
# }
