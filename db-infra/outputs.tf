output "db_instance_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.rds.endpoint
}

output "secret_arn" {
  description = "ARN of the master password secret in Secrets Manager"
  value       = aws_db_instance.rds.master_user_secret[0].secret_arn
}
