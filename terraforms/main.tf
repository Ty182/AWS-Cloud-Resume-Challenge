import {
  to = aws_s3_bucket.bucket
  id = "tyler-s3bucketlogs1"
}

module "website_infra_configuration" {
  source                        = "./modules/website_infra_configuration"
  bucket_name_main              = "tylerpettycloudresumechallenge.com"
  bucket_name_subdomain         = "www.tylerpettycloudresumechallenge.com"
  cloudfront_acm_cert_reference = "tylerpettycloudresumechallenge.com"
  cloudfront_min_tls_version    = "TLSv1.2_2021"
  cloudfront_price_class        = "PriceClass_100"
  cloudfront_geo_restriction = {
    locations = []
    type      = "none"
  }
  cloudfront_logging = aws_s3_bucket.bucket.bucket_domain_name
  s3_bucket_logging  = aws_s3_bucket.bucket.id
}

module "dynamodb_configuration" {
  source = "./modules/dynamodb_configuration/"
}

module "iam_configuration" {
  source       = "./modules/iam_configuration/"
  dynamodb_arn = module.dynamodb_configuration.dynamodb_table_arn
}

module "lambda_configuration" {
  source                     = "./modules/lambda_configuration/"
  lambda_iam_arn             = module.iam_configuration.lambda_iam_arn
  api_gateway_deployment_arn = module.api_gateway_configuration.api_gateway_deployment_arn
  api_gateway_method         = module.api_gateway_configuration.api_gateway_method
}

module "api_gateway_configuration" {
  source            = "./modules/api_gateway_configuration/"
  lambda_invoke_arn = module.lambda_configuration.lambda_invoke_arn
}
