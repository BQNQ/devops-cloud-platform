terraform {
  ### Uncomment after first apply and run terraform init -migrate-state
  #   backend "s3" {
  #     region       = "<region>"
  #     bucket       = "<tfstate-bucket-name>"
  #     use_lockfile = true
  #     encrypt      = true
  #     key          = "backend/terraform.tfstate"
  #   }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "<region>"
}

module "tfstate-bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"
  bucket = "<tfstate-bucket-name>"

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
