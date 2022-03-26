# cloudposse-terraform-demo

Terraform script to deploy a static website using Cloudposse S3 and Cloudfront modules.

## Prerequisites
1. Install Terraform v1.1.7.
2. Create a terraform.tfvars file in the root directory. Example below.

## Variables

Below is an example `terraform.tfvars` file that you can use in your deployments:

```ini
region                 = "us-east-1"
website_domain_name    = "cloudposse-demo.xyz"
stage                  = "demo"
namespace              = "cp"
route53_hosted_zone_id = "Z040409836SNWYFDUNQ8R"
```

## Usage

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```
