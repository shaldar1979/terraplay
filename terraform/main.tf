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
