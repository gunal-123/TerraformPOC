output "primary_bucket_name" {
  description = "Bucket name of primary bucket"
  value       = aws_s3_bucket.primary_bucket.id
}
output "secondary_bucket_name" {
  description = "Bucket name of secondary bucket"
  value       = aws_s3_bucket.secondary_bucket.id
}
output "distribution_domain" {
  description = "Domain name of cloudfront distribution"
  value       = aws_cloudfront_distribution.poc_distribution.domain_name
}
output "distribution_domain_id" {
description = "Domain id of cloudfront distribution"
value = aws_cloudfront_distribution.poc_distribution.id
}
