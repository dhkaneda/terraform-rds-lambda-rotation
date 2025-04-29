resource "aws_s3_bucket" "lambda" {

}

resource "aws_s3_object" "test_arn" {
  bucket  = aws_s3_bucket.lambda.id
  key     = secret_arn
  content = var.rds_master_secret_arn
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
