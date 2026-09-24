output "primary_bucket_name" {
  description = "Bucket name of primary bucket"
  value       = aws_s3_bucket.pocproject["pocbucket1"].id
}
output "secondary_bucket_name" {
  description = "Bucket name of secondary bucket"
  value = aws_s3_bucket.pocproject["pocbucket2"].id
}
output "distribution_domain" {
  description = "Domain name of cloudfront distribution"
  value       = aws_cloudfront_distribution.poc_distribution.domain_name
}
