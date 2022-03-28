# cloudposse-terraform-demo

Terraform script to deploy a static website using Cloudposse S3 and Cloudfront modules.

## Prerequisites
1. Install Terraform v1.1.7.
2. Configure AWS credentials in the Github secrets (AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY)
3. Start Github action and provide necessary inputs.

## Usage

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```
