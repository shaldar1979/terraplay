locals {
  lambda_env_vars = {
    env1 = {
      APP_MODE = "environment_one"
    }
    env2 = {
      APP_MODE = "environment_two"
    }
  }

  dag_variables = {
    env1 = {
      api_url  = "https://api.env1.example.com"
      db_name  = "env1_database"
    }
    env2 = {
      api_url  = "https://api.env2.example.com"
      db_name  = "env2_database"
    }
  }
  
  cidr_block = {
    env1 = "10.10.0.0/16"
    env2 = "10.20.0.0/16"
  }

}


data "aws_caller_identity" "current" {}

module "app_bucket" {
  source = "../modules/s3-bucket"

  bucket_name = "${var.bucket_name}-${var.environment}-${data.aws_caller_identity.current.account_id}"


  tags = {
    Environment = "dev"
    Project     = "terraform-s3-demo"
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.root}/../lambda-code"
  output_path = "${path.root}/lambda_function.zip"
}

module "sqs_queue" {
  source     = "../modules/sqs"
  queue_name = "demo-sqs-queue"
}

module "lambda_function" {
  source = "../modules/lambda"

  function_name    = "demo-lambda-${var.environment}"
  lambda_zip_path  = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  sqs_queue_arn    = module.sqs_queue.queue_arn

  environment_variables = local.lambda_env_vars[var.environment]
}

data "template_file" "dag_template" {
  template = file("${path.module}/../dags/sample_dag.py.tpl")

  vars = local.dag_variables[var.environment]
}


module "mwaa" {
  source = "../modules/mwaa"

  environment_name   = "mwaa-${var.environment}"
  vpc_id             = var.vpc_id
  private_subnet_ids = var.private_subnet_ids
}



resource "aws_vpc" "this" {
  cidr_block           = local.cidr_block[var.environment]
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "mwaa-${var.environment}-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}


resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(local.cidr_block[var.environment], 8, 1)
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(local.cidr_block[var.environment], 8, 2)
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}b"
}



resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(local.cidr_block[var.environment], 8, 3)
  availability_zone = "${var.aws_region}a"
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(local.cidr_block[var.environment], 8, 4)
  availability_zone = "${var.aws_region}b"
}


resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}


resource "aws_s3_bucket" "mwaa_bucket" {
  bucket = "mwaa-${var.environment}-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}


resource "aws_iam_role" "mwaa_exec_role" {
  name = "mwaa-${var.environment}-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "airflow.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}


resource "aws_iam_role_policy_attachment" "mwaa_policy" {
  role       = aws_iam_role.mwaa_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonMWAAServiceRolePolicy"
}

resource "aws_mwaa_environment" "this" {
  name               = "mwaa-${var.environment}"
  airflow_version    = "2.8.1"
  environment_class  = "mw1.small"
  execution_role_arn = aws_iam_role.mwaa_exec_role.arn

  source_bucket_arn = aws_s3_bucket.mwaa_bucket.arn
  dag_s3_path       = "dags"

  network_configuration {
    subnet_ids         = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    security_group_ids = []
  }

  max_workers = 2
}


data "template_file" "dag_template" {
  template = file("${path.module}/../dags/sample_dag.py.tpl")
  vars     = local.dag_variables[var.environment]
}


resource "aws_s3_object" "dag_upload" {
  bucket  = aws_s3_bucket.mwaa_bucket.id
  key     = "dags/sample_dag.py"
  content = data.template_file.dag_template.rendered
}



