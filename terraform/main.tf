module "app_bucket" {
  source = "../modules/s3-bucket"

  bucket_name       = var.bucket_name
  enable_versioning = true
  enable_encryption = true

  tags = {
    Environment = "dev"
    Project     = "terraform-s3-demo"
  }
}