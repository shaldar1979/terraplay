variable "function_name" {
  type = string
}

variable "lambda_zip_path" {
  type = string
}

variable "source_code_hash" {
  type = string
}

variable "sqs_queue_arn" {
  type = string
}

variable "environment_variables" {
  description = "Environment variables for Lambda"
  type        = map(string)
  default     = {}
}
