output "bucket_name" {
  value = module.app_bucket.bucket_id
}

output "bucket_arn" {
  value = module.app_bucket.bucket_arn
}