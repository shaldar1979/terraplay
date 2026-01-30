data "aws_caller_identity" "current" {}

module "app_bucket" {
  source = "../modules/s3-bucket"

  bucket_name = "${var.bucket_name}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Environment = "dev"
    Project     = "terraform-s3-demo"
  }
}