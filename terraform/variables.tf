variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "bucket_name" {
  type = string
}

variable "lambda_name" {
  description = "Lambda function name"
  type        = string
  default     = "demo-lambda"
}

variable "sqs_name" {
  description = "SQS queue name"
  type        = string
  default     = "demo-sqs-queue"
}