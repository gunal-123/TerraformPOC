output "distribution_domain" {
description = "Domain name of cloudfront distribution"
value = aws_cloudfront_distribution.poc_distribution.domain_name
}
