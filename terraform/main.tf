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


provider "aws" {
  region = var.aws_region
}

locals {
  environments = ["env1", "env2"]

  email_address = "shouvanik.haldar@accenture.com"
}

resource "aws_sns_topic" "env_topics" {
  for_each = toset(local.environments)

  name = "demo-sns-${each.key}"
}


resource "aws_sns_topic_subscription" "email_subscriptions" {
  for_each = aws_sns_topic.env_topics

  topic_arn = each.value.arn
  protocol  = "email"
  endpoint  = local.email_address
}

output "sns_topic_arns" {
  value = {
    for env, topic in aws_sns_topic.env_topics :
    env => topic.arn
  }
}
