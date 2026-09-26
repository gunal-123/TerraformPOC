terraform {
required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source = "hashicorp/random"
      version = "~>3.9.1"
  }
}
}
# Configure the AWS Provider
provider "aws" {
region = "us-east-1"
}

#Create random id
resource "random_id" "bucket_id" {
byte_length = 4
}

#Create S3 bucket
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_s3_bucket" "example" {
  bucket           = format("backend-bucket-%s-%s-%s-an", random_id.bucket_id.hex, data.aws_caller_identity.current.account_id, data.aws_region.current.region)
  bucket_namespace = "account-regional"
}


