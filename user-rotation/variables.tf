variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "galv-enterprise"
}

variable "rds_master_secret_arn" {
  description = "RDS master user password (from Secrets Manager, ARN)"
  type        = string
}

variable "rds_endpoint" {
  description = "RDS endpoint, may include port (e.g. host:5432)"
  type        = string
}

# Locals to parse host and port from rds_endpoint
locals {
  rds_endpoint_host = regex("^([^:]+)", var.rds_endpoint)[0]
  rds_endpoint_port = length(regexall(":(\\d+)$", var.rds_endpoint)) > 0 ? tonumber(regex(":(\\d+)$", var.rds_endpoint)[0]) : 5432
}


variable "app_user_password" {
  description = "Password for the app_user created by db-setup"
  type        = string
  default = "changeme"
}