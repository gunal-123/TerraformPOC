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

# Create bucket using regional-namespace
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_s3_bucket" "pocproject" {
  bucket           = format("pocbucket-%s-%s-an", data.aws_caller_identity.current.account_id, data.aws_region.current.region)
  bucket_namespace = "account-regional"

  tags = {
    Name        = "project"
    Environment = "Dev"
  }
}

#Upload two objects to bucket
resource "aws_s3_object" "pocobject" {
  for_each = toset(["index.html", "error.html"])
  bucket   = aws_s3_bucket.pocproject.id
  key      = each.value
  source   = "${path.module}/${each.value}"
  content_type = "text/html"
}

#Enable web hosting
resource "aws_s3_bucket_website_configuration" "pocwebsite" {
  bucket = aws_s3_bucket.pocproject.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

#Disable "Block all public access"
resource "aws_s3_bucket_public_access_block" "pocpublic" {
bucket = aws_s3_bucket.pocproject.id
 block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

#Adding bucket policy
resource "aws_s3_bucket_policy" "allow_public_access" {
bucket = aws_s3_bucket.pocproject.id
policy = data.aws_iam_policy_document.allow_public_access.json
}

data "aws_iam_policy_document" "allow_public_access" {
statement {
principals {
type = "AWS"
identifiers = ["*"]
}
actions = ["s3:GetObject"]
resources = [
	aws_s3_bucket.pocproject.arn,
	"${aws_s3_bucket.pocproject.arn}/*"
	]
}
}

