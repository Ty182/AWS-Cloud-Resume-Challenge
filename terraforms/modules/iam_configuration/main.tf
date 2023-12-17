# get aws account number
data "aws_caller_identity" "current" {
}

# define an iam permissions policy 
data "aws_iam_policy_document" "dynamodb_access" {
  statement {
    sid    = "ProvidesDynamodbAccess"
    effect = "Allow"
    actions = [
      "dynamodb:BatchGetItem",
      "dynamodb:GetItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchWriteItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem"
    ]
    resources = [
      "${var.dynamodb_arn}"
    ]
  }
  statement {
    sid    = "AllowCloudwatchLogWrite"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:*"
    ]
  }
  statement {
    sid    = "AllowCloudwatchLogGroupCreation"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup"
    ]
    resources = [
      "*"
    ]
  }
}

# define an iam trust policy 
data "aws_iam_policy_document" "trustpolicy" {
  statement {
    sid    = "AllowLambdaAssumeRole"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = [
      "sts:AssumeRole"
    ]
  }
}

# create iam permissions policy
resource "aws_iam_policy" "cloudresumechallengerole" {
  policy = data.aws_iam_policy_document.dynamodb_access.json
  name   = "cloudresumechallenge_lambda_role"
}

# create IAM resource
resource "aws_iam_role" "cloudresumechallengerole" {
  name                = "cloudresumechallenge_lambda_role"
  description         = "Allows Lambda functions to call AWS services on your behalf."
  managed_policy_arns = [aws_iam_policy.cloudresumechallengerole.arn]
  assume_role_policy  = data.aws_iam_policy_document.trustpolicy.json
}

output "lambda_iam_arn" {
  value = aws_iam_role.cloudresumechallengerole.arn
}
