variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
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

variable "bucket_name" {
  description = "Base name of the S3 bucket"
  type        = string
  default     = "app-bucket"
}

variable "environment" {
  description = "Deployment environment (env1 or env2)"
  type        = string
}
