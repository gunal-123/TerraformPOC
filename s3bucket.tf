terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create bucket
resource "aws_s3_bucket" "pocproject" {
bucket = "pocbucket-temporary-546821"

tags = {
Name = "project"
Environment = "Dev"
}
}
