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
  description = "ARN of the RDS instance master secret stored in Secrets Manager"
  type        = string
}