
resource "random_pet" "secret_name" {
  length = 2
}

resource "aws_secretsmanager_secret" "app_user_credentials" {
  name = "app-user-credentials-${random_pet.secret_name.id}"
}

resource "aws_secretsmanager_secret_version" "app_user_credentials_version" {
  secret_id     = aws_secretsmanager_secret.app_user_credentials.id
  secret_string = jsonencode({
    engine                = "postgres"
    host                  = local.rds_endpoint_host
    username              = "app_user"
    password              = var.app_user_password
    dbname                = "animals"
    port                  = local.rds_endpoint_port
    masterarn             = var.rds_master_secret_arn
  })
}


data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_rotation" {
  name = "lambda-rotation-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_rotation.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom policy for Lambda to access Secrets Manager and RDS
resource "aws_iam_policy" "lambda_rotation_custom" {
  name   = "lambda-rotation-custom"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:UpdateSecretVersionStage"
        ]
        Resource = [
          aws_secretsmanager_secret.app_user_credentials.arn,
          var.rds_master_secret_arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:ListSecrets",
          "secretsmanager:GetRandomPassword"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds:DescribeDBClusterEndpoints"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "rds-db:connect"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_rotation_custom_attach" {
  role       = aws_iam_role.lambda_rotation.name
  policy_arn = aws_iam_policy.lambda_rotation_custom.arn
}

resource "aws_lambda_function" "rotate_secret" {
  function_name    = "rotate-app-user-secret"
  handler          = "rotate_secret.lambda_handler"
  runtime          = "python3.11"
  role             = aws_iam_role.lambda_rotation.arn
  filename         = "${path.module}/lambda/build.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/build.zip")
  memory_size      = 1024
  timeout          = 300
  environment {
    variables = {
      SECRET_ARN = aws_secretsmanager_secret.app_user_credentials.arn
      # Add more as needed
    }
  }
}

resource "aws_lambda_permission" "allow_secretsmanager_rotation" {
  statement_id  = "AllowExecutionFromSecretsManager"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotate_secret.function_name
  principal     = "secretsmanager.amazonaws.com"
  source_arn    = aws_secretsmanager_secret.app_user_credentials.arn
}


resource "aws_secretsmanager_secret_rotation" "app_user_rotation" {
  secret_id           = aws_secretsmanager_secret.app_user_credentials.id
  rotation_lambda_arn = aws_lambda_function.rotate_secret.arn
  rotation_rules {
    automatically_after_days = 30
  }
}
