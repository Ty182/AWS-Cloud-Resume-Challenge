# creates the API
resource "aws_api_gateway_rest_api" "crc" {
  name        = "cloudresumechallenge-api"
  description = "Enables Lambda to read/write to Dynamodb."
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# creates the "Method Request" for the GET method
resource "aws_api_gateway_method" "get" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_rest_api.crc.root_resource_id
  rest_api_id   = aws_api_gateway_rest_api.crc.id
}

# needed for the lambda permissions (allows api to invoke our lambda function)
output "api_gateway_method" {
  value = aws_api_gateway_method.get.http_method
}

# creates the "Integration Request" for the GET method
resource "aws_api_gateway_integration" "crc" {
  integration_http_method = "POST"
  content_handling        = "CONVERT_TO_TEXT"
  uri                     = var.lambda_invoke_arn
  http_method             = aws_api_gateway_method.get.http_method
  resource_id             = aws_api_gateway_rest_api.crc.root_resource_id
  rest_api_id             = aws_api_gateway_rest_api.crc.id
  type                    = "AWS"

}

# creates the "Integration Response" for GET method
resource "aws_api_gateway_integration_response" "crc_response" {
  http_method = aws_api_gateway_method.get.http_method                   # GET
  resource_id = aws_api_gateway_rest_api.crc.root_resource_id            # API resource ID
  rest_api_id = aws_api_gateway_rest_api.crc.id                          # ID of the associated REST API
  status_code = aws_api_gateway_method_response.response_200.status_code # 200, HTTP status code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'" # restrict origin, * allows anything
  }

  response_templates = {
    "application/json" = ""
  }
}

# creates the "Method Response" for GET method
resource "aws_api_gateway_method_response" "response_200" {
  http_method = aws_api_gateway_method.get.http_method
  resource_id = aws_api_gateway_rest_api.crc.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.crc.id
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = false
  }

  response_models = {
    "application/json" = "Empty" # response body
  }

}

# creates the "Method Request" for the OPTIONS method
resource "aws_api_gateway_method" "options" {
  authorization = "NONE"
  http_method   = "OPTIONS"
  resource_id   = aws_api_gateway_rest_api.crc.root_resource_id
  rest_api_id   = aws_api_gateway_rest_api.crc.id
}

# creates the "Integration Request" for the OPTIONS method
resource "aws_api_gateway_integration" "options" {
  cache_key_parameters = []
  http_method          = aws_api_gateway_method.options.http_method
  resource_id          = aws_api_gateway_rest_api.crc.root_resource_id
  rest_api_id          = aws_api_gateway_rest_api.crc.id
  type                 = "MOCK"

  request_parameters = {}
  request_templates = {
    "application/json" = jsonencode(
      {
        statusCode = 200
      }
    )
  }
}

# creates the "Integration Response" for OPTIONS method
resource "aws_api_gateway_integration_response" "options" {
  http_method = aws_api_gateway_method.options.http_method                       # GET
  resource_id = aws_api_gateway_rest_api.crc.root_resource_id                    # API resource ID
  rest_api_id = aws_api_gateway_rest_api.crc.id                                  # ID of the associated REST API
  status_code = aws_api_gateway_method_response.options_response_200.status_code # 200, HTTP status code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'" # restrict origin, * allows anything
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# creates the "Method Response" for GET method
resource "aws_api_gateway_method_response" "options_response_200" {
  http_method = aws_api_gateway_method.options.http_method
  resource_id = aws_api_gateway_rest_api.crc.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.crc.id
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false
    "method.response.header.Access-Control-Allow-Methods" = false
    "method.response.header.Access-Control-Allow-Origin"  = false
  }

  response_models = {
    "application/json" = "Empty" # response body
  }

}

# deploys the api endpoint
resource "aws_api_gateway_deployment" "crc" {
  rest_api_id = aws_api_gateway_rest_api.crc.id

  depends_on = [
    aws_api_gateway_method.get
  ]
}

# needed for the lambda permissions
output "api_gateway_deployment_arn" {
  value = aws_api_gateway_deployment.crc.execution_arn
}

resource "aws_api_gateway_stage" "crc" {
  deployment_id = aws_api_gateway_deployment.crc.id
  rest_api_id   = aws_api_gateway_deployment.crc.rest_api_id
  stage_name    = "get-visitor-count"
}
