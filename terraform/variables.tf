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
