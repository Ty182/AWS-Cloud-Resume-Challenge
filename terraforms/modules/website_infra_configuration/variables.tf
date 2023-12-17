variable "bucket_name_main" {
  description = "This should match your domain e.g., example.com"
  type        = string
}

variable "bucket_name_subdomain" {
  description = "This should match your sub-domain e.g., www.example.com"
  type        = string
}

variable "cloudfront_acm_cert_reference" {
  description = "An existing ACM certificate to reference. Should be the Fully qualified domain name (FQDN) in the certificate."
  type        = string
}

variable "cloudfront_min_tls_version" {
  description = "The minimum TLS version to use."
  type        = string
}

variable "cloudfront_price_class" {
  description = "Determines which edge locations website content is cached in. Users not near an edge location used may experience higher latency."
  type        = string
}

variable "cloudfront_geo_restriction" {
  description = "Optionally allow/deny a set of geolocations"
  type = object({
    type      = string
    locations = list(string)
  })
  default = {
    type      = "none"
    locations = []
  }
}

variable "cloudfront_logging" {
  description = "The S3 bucket used for logging"
  type        = string
}

variable "s3_bucket_logging" {
  description = "The S3 ID of the logging bucket"
  type        = string
}
