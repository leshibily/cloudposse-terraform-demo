# main.tf

module "s3-bucket" {
  source                  = "cloudposse/s3-bucket/aws"
  version                 = "0.49.0"
  acl                     = "public-read"
  restrict_public_buckets = false
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  enabled                 = true
  versioning_enabled      = false
  force_destroy           = true
  name                    = var.website_domain_name
  stage                   = var.stage
  namespace               = var.namespace
  privileged_principal_arns = [
    {
      "*" = [""]
  }]
  privileged_principal_actions = [
    "s3:GetObject"
  ]
}

resource "aws_s3_bucket_website_configuration" "this" {
  bucket = module.s3-bucket.bucket_id
  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

  depends_on = [module.s3-bucket]
}

###
# facing hashicorp/aws version error when using the cloudfront-s3-cdn.
# version error: Could not retrieve the list of available versions for provider hashicorp/aws: locked provider registry.terraform.io/hashicorp/aws 4.4.0 does not match
# configured version constraint >= 2.0.0, >= 3.0.0, >= 3.64.0, < 4.0.0, >= 4.2.0, ~> 4.4.0; must use terraform init -upgrade to allow selection of new
# versions
###
# module "cloudfront-s3-cdn" {
#   source  = "cloudposse/cloudfront-s3-cdn/aws"
#   version = "0.82.3"
#   name      = "testleshibilyxyzcdn"
#   stage     = "test"
#   namespace = "demo"
#   aliases = ["cloudposse-demo.xyz"]
#   parent_zone_id = "Z07973632MBUD2XUK6IJW"
#   depends_on = [module.s3-bucket]
# }

# resource aws_route53_zone "this" {
#   name = var.website_domain_name
#   comment = "Static website"
# }

module "acm_request_certificate" {
  source                            = "cloudposse/acm-request-certificate/aws"
  version                           = "0.16.0"
  domain_name                       = var.website_domain_name
  process_domain_validation_options = true
  ttl                               = "300"
  subject_alternative_names         = ["*.${var.website_domain_name}"]
  zone_id                           = var.route53_hosted_zone_id
  wait_for_certificate_issued       = true
}

# using terraform-aws-modules/cloudfront module instead of
# cloudposse/cloudfront-s3-cdn because it's provider verions are outdated.
module "cdn" {
  source = "terraform-aws-modules/cloudfront/aws"

  aliases = ["www.${var.website_domain_name}"]

  comment             = "Static Website CDN"
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  retain_on_delete    = false
  wait_for_deployment = false

  create_origin_access_identity = true
  origin_access_identities = {
    s3_bucket_one = "My awesome CloudFront can access"
  }
  default_root_object = "index.html"

  origin = {
    my_domain = {
      domain_name = "www.${var.website_domain_name}"
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "match-viewer"
        origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
      }
    }

    static_website_s3 = {
      domain_name = module.s3-bucket.bucket_domain_name
      s3_origin_config = {
        origin_access_identity = "s3_bucket_one"
      }
    }
  }

  default_cache_behavior = {
    target_origin_id       = "my_domain"
    viewer_protocol_policy = "allow-all"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true
    query_string    = true
  }

  ordered_cache_behavior = [
    {
      path_pattern           = "/*"
      target_origin_id       = "static_website_s3"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = ["GET", "HEAD", "OPTIONS"]
      cached_methods  = ["GET", "HEAD"]
      compress        = true
      query_string    = true
    }
  ]

  viewer_certificate = {
    acm_certificate_arn = module.acm_request_certificate.arn
    ssl_support_method  = "sni-only"
  }

  custom_error_response = [
    {
      error_caching_min_ttl = "10"
      error_code            = "404"
      response_code         = "404"
      response_page_path    = "/error.html"
  }]

  depends_on = [module.acm_request_certificate, module.s3-bucket]
}

resource "aws_route53_record" "this" {
  zone_id    = var.route53_hosted_zone_id
  name       = "www.${var.website_domain_name}"
  type       = "CNAME"
  ttl        = "60"
  records    = [module.cdn.cloudfront_distribution_domain_name]
  depends_on = [module.cdn]
}