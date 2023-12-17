variable "lambda_iam_arn" {
  type        = string
  description = "The ARN of the IAM Role Lambda assumes."
}

variable "api_gateway_deployment_arn" {
  type        = string
  description = "The ARN of the API Gateway"
}

variable "api_gateway_method" {
  type        = string
  description = "The HTTP method of the API Gateway"
}
