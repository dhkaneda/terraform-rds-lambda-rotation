# terraform-rds-lambda-rotation
Provision an AWS RDS Postgres Database Instance via Terraform with Alternating User Secret Rotation via Lambda

## Requirements

- AWS CLI
- Terraform

## Overview

This project provisions an AWS RDS Postgres Database Instance with a master user password stored in AWS Secrets Manager. It also provisions an AWS Lambda function that rotates the app user password stored in AWS Secrets Manager using the master user password. The rotation method uses an alternating user method. By default, the app user password is rotated every 30 days. You can trigger the rotation manually in the AWS Secret Manager console.

The `db-setup` directory would need to be modified to fit your needs.

## Recommended Use

It is recommended you deploy this project's resource through GitLab CI/CD. If you want to debug or develop locally, see the section [Local init with GitLab Terraform State](#local-init-with-gitlab-terraform-state).

1. Fork this repository to your desired group.
1. You will need an AWS IAM User's security credentials with permissions to create an RDS Postgres Database Instance, Lambda functions, Secrets Manager secrets, and accompanying IAM resources. See the included .tf files for the required permissions if you want to create a minimal IAM user.
1. Navigate to the project's CI/CD Variables and provide the following:
    - AWS_ACCESS_KEY_ID
    - AWS_SECRET_ACCESS_KEY
    - AWS_DEFAULT_REGION

1. Checkout the `variables.tf` files in the `db-infra` and `user-rotation` directories in case you need to modify the variables.
1. Ensure the `db-setup` directory is modified to fit your needs.
1. Run the pipeline and trigger the manual jobs to deploy the resources.
1. Clean up is handled by the manual `destroy` jobs in the pipeline.

## Local init with GitLab Terraform State

Your local setup will follow the same order as the pipeline. Here are the high level setps:

1. Create a GitLab Personal Access Token
1. `terraform init` in the `db-infra` directory
1. Export AWS environment variables
1. Export the rest of the environment variables from the `all_outputs.env` file in the `db-infra` directory
1. Set up the database with tables and a user
1. `terraform apply` in the `user-rotation` directory
1. Test the rotation in the AWS Secret Manager console

Create a Personal Access Token from GitLab and set it as an environment variable

```bash
export GITLAB_ACCESS_TOKEN=<YOUR-ACCESS-TOKEN>
```

In the Project repository, navigate to **Operate > Terraform States** and copy the init command, supplying the needed values. It should look like this (Do not use this exact command).

```bash
export TF_STATE_NAME=default
terraform init \
    -backend-config="address=https://gitlab.com/api/v4/projects/10832/terraform/state/$TF_STATE_NAME" \
    -backend-config="lock_address=https://gitlab.com/api/v4/projects/10832/terraform/state/$TF_STATE_NAME/lock" \
    -backend-config="unlock_address=https://gitlab.com/api/v4/projects/10832/terraform/state/$TF_STATE_NAME/lock" \
    -backend-config="username=dennis.huynh" \
    -backend-config="password=$GITLAB_ACCESS_TOKEN" \
    -backend-config="lock_method=POST" \
    -backend-config="unlock_method=DELETE" \
    -backend-config="retry_wait_min=5"
```

This project contains TWO Terraform modules:

- `db-infra` - provisions an AWS RDS Postgres Database Instance with a master user password stored in AWS Secrets Manager
- `user-rotation` - provisions an AWS Lambda function that rotates the app user password stored in AWS Secrets Manager using the master user password

You'll need to run `terraform init` for each module. It is recommended you use different state names for each module. For example:

- `TF_STATE_NAME=rds` for the db-infra module
- `TF_STATE_NAME=lambda` for the user-rotation module

Then, run `terraform apply` in the `db-infra` directory. Don't apply `user-rotation` yet.

If you want to run the `db-setup` scripts locally, you'll need to set the following environment variables:

```bash
AWS_ACCESS_KEY_ID=<YOUR-ACCESS-KEY-ID>
AWS_SECRET_ACCESS_KEY=<YOUR-SECRET-ACCESS-KEY>
AWS_DEFAULT_REGION=<YOUR-DEFAULT-REGION>
```

In the `db-infra` directory, after running `terraform apply`, you can run the `generate-env.sh` script to generate a `.env` file with the outputs from the `terraform output` command.

```bash
./generate-env.sh
```

Then run the following command to export the variables from the `.env` file:

```bash
export $(grep -v '^#' all_outputs.env | xargs)
```

You can then run the `db-setup` script to set up the database.

```bash
docker run -it --rm \
  -v "$PWD/db-setup:/db-setup" \
  -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
  -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
  -e AWS_DEFAULT_REGION="$AWS_DEFAULT_REGION" \
  -e TF_VAR_rds_endpoint="$TF_VAR_rds_endpoint" \
  -e TF_VAR_rds_master_secret_arn="$TF_VAR_rds_master_secret_arn" \
  -e TF_VAR_rds_master_user="$TF_VAR_rds_master_user" \
  postgres:14 bash
```

```bash
apt-get update && apt-get install -y awscli jq
cd /db-setup
./setup.sh
```

You can then run the `user-rotation` module to rotate the app user password. Change into the `user-rotation` directory and run `terraform apply`.

Once everything is set up, you can test the rotation in the AWS Secret Manager console.

The rotation Lambda automatically logs to CloudWatch. You can view the logs in the AWS CloudWatch console.
