# terraform-rds-lambda-rotation
Provision an AWS RDS Postgres Database Instance via Terraform with Alternating User Secret Rotation via Lambda

## Requirements

- AWS CLI
- Terraform

## GitLab Terraform State

Create a Personal Access Token from GitLab

In the Project repository, navigate to **Operate > Terraform States** and copy the init command, supplying the needed values. It should look like this:

```bash
export GITLAB_ACCESS_TOKEN=<YOUR-ACCESS-TOKEN>
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

## AWS

Run `aws configure` to set up your AWS credentials
