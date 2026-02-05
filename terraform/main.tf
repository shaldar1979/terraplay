data "aws_caller_identity" "current" {}

module "app_bucket" {
  source = "../modules/s3-bucket"

  bucket_name = "${var.bucket_name}-${var.environment}-${data.aws_caller_identity.current.account_id}"


  tags = {
    Environment = "dev"
    Project     = "terraform-s3-demo"
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.root}/../lambda-code"
  output_path = "${path.root}/lambda_function.zip"
}

data "archive_file" "api_lambda_zip" {
  type        = "zip"
  source_file = "${path.root}/../lambda-code/api_lambda.py"
  output_path = "${path.root}/api_lambda.zip"
}



module "sqs_queue" {
  source     = "../modules/sqs"
  queue_name = "demo-sqs-queue"
}

module "lambda_function" {
  source = "../modules/lambda"

  function_name    = "demo-lambda-${var.environment}"
  lambda_zip_path  = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  sqs_queue_arn    = module.sqs_queue.queue_arn

  environment_variables = local.lambda_env_vars[var.environment]
}

locals {
  environments = ["env1", "env2"]

  email_address = "shouvanik.haldar@accenture.com"
}

resource "aws_sns_topic" "this" {
  name = "demo-sns-${var.environment}"
}


resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.this.arn
  protocol  = "email"
  endpoint  = "shouvanik.haldar@accenture.com"
}

output "sns_topic_arn" {
  value = aws_sns_topic.this.arn
}

resource "aws_iam_role" "api_lambda_role" {
  name = "api-lambda-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "api_lambda_basic" {
  role       = aws_iam_role.api_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_lambda_function" "api_lambda" {
  function_name = "api-lambda-${var.environment}"
  role          = aws_iam_role.api_lambda_role.arn
  handler       = "api_lambda.lambda_handler"
  runtime       = "python3.11"

  filename         = data.archive_file.api_lambda_zip.output_path
  source_code_hash = data.archive_file.api_lambda_zip.output_base64sha256

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.api_lambda_basic
  ]
}

resource "aws_api_gateway_rest_api" "api" {
  name = "api-gateway-${var.environment}"
}


resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "{proxy+}"
}


resource "aws_api_gateway_method" "any" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}


resource "aws_api_gateway_integration" "lambda" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.any.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"

  uri = aws_lambda_function.api_lambda.invoke_arn
}


resource "aws_api_gateway_deployment" "deploy" {
  depends_on = [
    aws_api_gateway_integration.lambda
  ]

  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = var.environment
}


resource "aws_lambda_permission" "apigw_permission" {
  statement_id  = "AllowAPIGatewayInvoke-${var.environment}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}


output "api_url" {
  value = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${var.aws_region}.amazonaws.com/${var.environment}"
}
