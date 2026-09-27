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

  default_root_object = "pages/index.html"
}
