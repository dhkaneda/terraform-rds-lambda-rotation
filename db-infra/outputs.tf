output "rds_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.rds.endpoint
}

output "rds_master_user" {
  description = "RDS master username"
  value       = aws_db_instance.rds.username
}

output "rds_master_secret_arn" {
  description = "RDS master user password (from Secrets Manager, ARN)"
  value       = aws_db_instance.rds.master_user_secret[0].secret_arn
}