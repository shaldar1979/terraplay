data "aws_caller_identity" "current" {}

module "app_bucket" {
  source = "../modules/s3-bucket"

  bucket_name = "${var.bucket_name}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Environment = "dev"
    Project     = "terraform-s3-demo"
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda-code"
  output_path = "${path.module}/lambda_function.zip"
}

module "sqs_queue" {
  source     = "../modules/sqs"
  queue_name = "demo-sqs-queue"
}

module "lambda_function" {
  source = "../modules/lambda"

  function_name   = "demo-lambda"
  lambda_zip_path = "${path.module}/lambda_function.zip"
  sqs_queue_arn   = module.sqs_queue.queue_arn
}
