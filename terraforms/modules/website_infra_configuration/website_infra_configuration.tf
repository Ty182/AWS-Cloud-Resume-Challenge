# creates s3 bucket to host website
# ignored tfsec finding, acceptable risk using aws managed key
#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket" "tpcrc" {
  bucket = var.bucket_name_main
}

resource "aws_s3_bucket_logging" "tpcrc" {
  bucket        = aws_S3_bucket.tpcrc.id
  target_bucket = var.s3_bucket_logging
  target_prefix = "crc_s3_log/"

}

# encrypts bucket
# ignored tfsec finding, acceptable risk using aws managed key
#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket_server_side_encryption_configuration" "tpcrc" {
  bucket = aws_s3_bucket.tpcrc.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }

}

# enables bucket versioning
resource "aws_s3_bucket_versioning" "tpcrc" {
  bucket = aws_s3_bucket.tpcrc.id
  versioning_configuration {
    status = "Enabled"
  }

}

# removes public access disablement 
resource "aws_s3_bucket_public_access_block" "allow_public_access" {
  bucket = aws_s3_bucket.tpcrc.id

  # ignored tfsec findings, needs to be public since it's a website
  #tfsec:ignore:aws-s3-block-public-acls
  block_public_acls = false
  #tfsec:ignore:aws-s3-block-public-policy
  block_public_policy = false
  #tfsec:ignore:aws-s3-ignore-public-acls
  ignore_public_acls = false
  #tfsec:ignore:aws-s3-no-public-buckets
  restrict_public_buckets = false
}

# enables s3 to host website
resource "aws_s3_bucket_website_configuration" "tpcrc" {
  bucket = aws_s3_bucket.tpcrc.id

  # file should be uploaded by ci 
  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# s3 bucket policy, allows cloudfront to read bucket
resource "aws_s3_bucket_policy" "allow_anon_access" {
  bucket = aws_s3_bucket.tpcrc.id
  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "CloudFront Read",
            "Effect": "Allow",
            "Principal": {
              "AWS": "${aws_cloudfront_origin_access_identity.users.iam_arn}"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${aws_s3_bucket.tpcrc.bucket}/*"
        }
    ]
  }
  EOF
  depends_on = [
    aws_s3_bucket_public_access_block.allow_public_access,
    aws_s3_bucket.tpcrc,
    aws_cloudfront_origin_access_identity.users
  ]
}


# creates s3 bucket for subdomain
# ignored tfsec finding, needs to be public since it's a website
# ignored tfsec finding, acceptable risk using aws managed key
#tfsec:ignore:aws-s3-block-public-acls
#tfsec:ignore:aws-s3-block-public-policy
#tfsec:ignore:aws-s3-ignore-public-acls
#tfsec:ignore:aws-s3-no-public-buckets
#tfsec:ignore:aws-s3-specify-public-access-block
#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket" "wwwtpcrc" {
  bucket = var.bucket_name_subdomain
}

resource "aws_s3_bucket_logging" "wwwtpcrc" {
  bucket        = aws_S3_bucket.wwwtpcrc.id
  target_bucket = var.s3_bucket_logging
  target_prefix = "crc_s3_log/"

}

# encrypts bucket
# ignored tfsec finding, acceptable risk using aws managed key
#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket_server_side_encryption_configuration" "wwwtpcrc" {
  bucket = aws_s3_bucket.wwwtpcrc.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }

}

# enables bucket versioning
resource "aws_s3_bucket_versioning" "wwwtpcrc" {
  bucket = aws_s3_bucket.wwwtpcrc.id
  versioning_configuration {
    status = "Enabled"
  }

}


# redirects subdomain to main bucket
resource "aws_s3_bucket_website_configuration" "wwwtpcrc" {
  bucket = aws_s3_bucket.wwwtpcrc.id
  redirect_all_requests_to {
    host_name = aws_s3_bucket_website_configuration.tpcrc.bucket
    protocol  = "http"
  }
}

# creates cloudfront identity for s3 bucket policy
resource "aws_cloudfront_origin_access_identity" "users" {
}

data "aws_acm_certificate" "tpcrc" {
  domain = var.cloudfront_acm_cert_reference

}

# creates cloudfront distribution
# ignored tfsec due to pricing
#tfsec:ignore:aws-cloudfront-enable-waf
resource "aws_cloudfront_distribution" "tpcrc" {
  aliases = [
    aws_s3_bucket.tpcrc.id,
    aws_s3_bucket.wwwtpcrc.id
  ]
  default_root_object = "index.html"
  is_ipv6_enabled     = true
  price_class         = var.cloudfront_price_class
  enabled             = true
  default_cache_behavior {
    compress         = true
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket_website_configuration.tpcrc.website_endpoint
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
  }
  origin {
    connection_attempts = 3
    connection_timeout  = 10
    domain_name         = aws_s3_bucket.tpcrc.bucket_domain_name
    origin_id           = aws_s3_bucket_website_configuration.tpcrc.website_endpoint
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.users.cloudfront_access_identity_path
    }
  }
  restrictions {
    geo_restriction {
      restriction_type = var.cloudfront_geo_restriction.type
      locations        = var.cloudfront_geo_restriction.locations
    }
  }
  viewer_certificate {
    acm_certificate_arn      = data.aws_acm_certificate.tpcrc.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = var.cloudfront_min_tls_version
  }
  logging_config {
    include_cookies = false
    bucket          = var.cloudfront_logging
    prefix          = "cloudfront"
  }
}

# update R53 'A' records for website with the cloudfront distribution created
resource "aws_route53_record" "a_record_updates_website" {
  name    = "tylerpettycloudresumechallenge.com"
  type    = "A"
  zone_id = "Z1010027148DN0SIMDIDM"

  alias {
    name                   = aws_cloudfront_distribution.tpcrc.domain_name
    zone_id                = aws_cloudfront_distribution.tpcrc.hosted_zone_id
    evaluate_target_health = false
  }

}

# update R53 'A' records for subdomain with the cloudfront distribution created
resource "aws_route53_record" "a_record_updates_subdomain" {
  name    = "www.tylerpettycloudresumechallenge.com"
  type    = "A"
  zone_id = "Z1010027148DN0SIMDIDM"

  alias {
    name                   = aws_cloudfront_distribution.tpcrc.domain_name
    zone_id                = aws_cloudfront_distribution.tpcrc.hosted_zone_id
    evaluate_target_health = false
  }

}
