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



#Block all public access
#resource "aws_s3_bucket_public_access_block" "pocprivate" {
#bucket = aws_s3_bucket.pocproject.id
# block_public_acls       = true
#  block_public_policy     = true
#  ignore_public_acls      = true
#  restrict_public_buckets = true
#}

#Adding bucket policy
resource "aws_s3_bucket_policy" "cloudfront_policy" {
bucket = aws_s3_bucket.pocproject.id
policy = data.aws_iam_policy_document.cloudfront_policy.json
}

data "aws_iam_policy_document" "cloudfront_policy" {
statement {
sid = "allowCloudfrontAccess"
effect = "Allow"
principals {
type = "Service"
identifiers = ["cloudfront.amazonaws.com"]
}
actions = ["s3:GetObject"]
resources = [
	"${aws_s3_bucket.pocproject.arn}/*"
	]
condition {
test = "StringEquals"
variable = "AWS:SourceArn"
values = [aws_cloudfront_distribution.poc_distribution.arn]
}
}
}

#Creating origin access control
resource "aws_cloudfront_origin_access_control" "pocoac" {
name = "myoac"
origin_access_control_origin_type = "s3"
signing_behavior = "always"
signing_protocol = "sigv4" 
}

#Creating cloudfront distribution
resource "aws_cloudfront_distribution" "poc_distribution" {
 origin {
    domain_name              = aws_s3_bucket.pocproject.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.pocoac.id
    origin_id                = "myS3Origin"
  }

  enabled             = true
default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "myS3Origin"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  default_root_object = "index.html"
}
