resource "aws_s3_bucket" "test_bucket" {
  
}

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

# resource "aws_db_instance" "rds" {
#   identifier              = var.db_instance_identifier
#   allocated_storage       = 20
#   storage_type            = "gp2"
#   engine                  = "mysql"
#   engine_version          = "8.0"
#   instance_class          = "db.t3.micro"
#   db_name                 = var.db_name
#   username                = var.db_username
#   password                = random_password.master_password.result
#   skip_final_snapshot     = true
#   publicly_accessible     = false
#   multi_az                = false
#   availability_zone       = "us-west-2a"
#   vpc_security_group_ids  = [aws_security_group.rds_sg.id]
#   db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
#   deletion_protection     = false
# }

# resource "aws_security_group" "rds_sg" {
#   name        = "rds-sg"
#   description = "Allow DB access"
#   vpc_id      = aws_vpc.main.id

#   ingress {
#     from_port   = 3306
#     to_port     = 3306
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"] # TODO: restrict as needed
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_vpc" "main" {
#   cidr_block = "10.0.0.0/16"
# }

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
