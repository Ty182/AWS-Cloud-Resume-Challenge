# automatically zip code
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

# create lambda function, upload zip file if hash has changed
# ignore tfsec finding due to cost
#tfsec:ignore:aws-lambda-enable-tracing
resource "aws_lambda_function" "cloudresumechallengelambda" {
  function_name    = "cloudresumechallengelambda"
  role             = var.lambda_iam_arn
  runtime          = "python3.9"
  handler          = "lambda_function.lambda_handler"
  package_type     = "Zip"
  architectures    = ["x86_64"]
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
}

output "lambda_invoke_arn" {
  value = aws_lambda_function.cloudresumechallengelambda.invoke_arn
}

resource "aws_lambda_permission" "crc_lambda_perms" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudresumechallengelambda.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_deployment_arn}*/${var.api_gateway_method}/"
}
