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

#Define bucket name
locals {
  bucket_names = ["pocbucket1", "pocbucket2"]
}

# Create bucket using regional-namespace
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_s3_bucket" "pocproject" {
  for_each         = toset(local.bucket_names)
  bucket           = format("%s-%s-%s-an", each.key, data.aws_caller_identity.current.account_id, data.aws_region.current.region)
  bucket_namespace = "account-regional"

  tags = {
    Name        = "project"
    Environment = "Dev"
  }
}

#Upload two objects to bucket
locals {
  objects = {
    "index.html" = "${path.module}/index.html"
    "error.html" = "${path.module}/error.html"
  }
}

resource "aws_s3_object" "pocobject" {
  for_each = {
    for pair in setproduct(
      keys(aws_s3_bucket.pocproject),
      keys(local.objects)
    ) :
    "${pair[0]}-${pair[1]}" => {
      bucket = pair[0]
      key    = pair[1]
      source = local.objects[pair[1]]
    }
  }
  bucket       = aws_s3_bucket.pocproject[each.value.bucket].id
  key          = each.value.key
  source       = each.value.source
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
  for_each = aws_s3_bucket.pocproject
  bucket   = each.value.id
  policy   = data.aws_iam_policy_document.cloudfront_policy[each.key].json
}

data "aws_iam_policy_document" "cloudfront_policy" {
  for_each = aws_s3_bucket.pocproject
  statement {
    sid    = "allowCloudfrontAccess"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions = ["s3:GetObject"]
    resources = [
      "${each.value.arn}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.poc_distribution.arn]
    }
  }
}

#Enabling versioning
resource "aws_s3_bucket_versioning" "poc_versioning" {
  for_each = aws_s3_bucket.pocproject
  bucket   = each.value.id
  versioning_configuration {
    status = "Enabled"
  }
}

#Creating origin access control
resource "aws_cloudfront_origin_access_control" "pocoac" {
  name                              = "myoac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

#Creating cloudfront distribution
resource "aws_cloudfront_distribution" "poc_distribution" {
  origin_group {
    origin_id = "groupS3"

    failover_criteria {
      status_codes = [403, 404, 500, 502]
    }

    member {
      origin_id = "primaryS3"
    }

    member {
      origin_id = "failoverS3"
    }
  }


  origin {
    domain_name              = aws_s3_bucket.pocproject["pocbucket1"].bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.pocoac.id
    origin_id                = "primaryS3"
  }

  origin {
    domain_name              = aws_s3_bucket.pocproject["pocbucket2"].bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.pocoac.id
    origin_id                = "failoverS3"
  }

  enabled = true
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "groupS3"

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
