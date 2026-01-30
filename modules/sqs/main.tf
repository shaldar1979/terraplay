resource "aws_sqs_queue" "this" {
  name                      = var.queue_name
  visibility_timeout_seconds = 120
}


output "queue_arn" {
  value = aws_sqs_queue.this.arn
}

output "queue_url" {
  value = aws_sqs_queue.this.url
}
