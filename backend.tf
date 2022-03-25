terraform {
  backend "s3" {
    bucket = "demo-leshibily-tf"
    key    = "backends/static-website/terraform.tfstate"
    region = "us-west-2"
  }
}