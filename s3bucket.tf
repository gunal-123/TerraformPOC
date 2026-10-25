data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_region" "aliased" {
  provider = aws.secondary
}

resource "aws_s3_bucket" "primary_bucket" {
  bucket           = format("primary-%s-%s-an", data.aws_caller_identity.current.account_id, data.aws_region.current.region)
  bucket_namespace = "account-regional"
}

resource "aws_s3_bucket_versioning" "primary_bucket" {
  bucket = aws_s3_bucket.primary_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "secondary_bucket" {
provider = aws.secondary
  bucket           = format("secondary-%s-%s-an", data.aws_caller_identity.current.account_id, data.aws_region.aliased.region)
  bucket_namespace = "account-regional"
}

resource "aws_s3_bucket_versioning" "secondary_bucket" {
provider = aws.secondary
  bucket = aws_s3_bucket.secondary_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_replication_configuration" "replication" {
  

  # Must have bucket versioning enabled first
  depends_on = [aws_s3_bucket_versioning.primary_bucket]

  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.primary_bucket.id

  rule {
    id = "htmlrule"

    filter {}

    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.secondary_bucket.arn
      storage_class = "STANDARD"
    }
  }
}
