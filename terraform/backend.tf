terraform {
  backend "s3" {
    bucket         = "haldar-terraform-state-117134819170-us-east-1"
    key            = "s3-project/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}