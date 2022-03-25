variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "website_domain_name" {
  type        = string
  description = "Static website FQDN"
}

variable "stage" {
  type        = string
  description = <<EOT
    (Optional)  The name of the environment where the resources will be deployed.

    Options:
      - dev
      - stag
      - prod
      - demo

    Default: demo
  EOT

  default = "demo"

  validation {
    condition     = can(regex("dev|stag|prod|demo", var.stage))
    error_message = "Err: environment name is not valid."
  }
}

variable "namespace" {
  type        = string
  description = "ID element. Usually an abbreviation of your organization name, e.g. 'eg' or 'cp', to help ensure generated IDs are globally unique"
}

variable "route53_hosted_zone_id" {
  type        = string
  description = "Route53 hosted zone id of the domain name."
}