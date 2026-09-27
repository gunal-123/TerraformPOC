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

#Enabling versioning
resource "aws_s3_bucket_versioning" "poc_versioning" {
  for_each = aws_s3_bucket.pocproject
  bucket   = each.value.id
  versioning_configuration {
    status = "Enabled"
  }
}


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
