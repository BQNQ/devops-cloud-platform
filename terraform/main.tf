terraform {
  backend "s3" {
    use_lockfile = true
    encrypt      = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "network" {
  source   = "./modules/network"
  vpc_name = var.environment == "dev" ? "flask-app-vpc-${var.environment}" : "flask-app-vpc"
  vpc_cidr = "10.0.0.0/16"
  public_subnet_cidr = [
    "10.0.0.0/20",
    "10.0.16.0/20"
  ]
  private_subnet_cidr = [
    "10.0.128.0/20",
    "10.0.144.0/20"
  ]
  azs = var.azs
  env = var.environment
}

module "ecr" {
  source = "./modules/ecr"
  env    = var.environment
}

module "eks" {
  source = "./modules/eks"

  private_subnet_ids = module.network.private_subnet_ids
  env                = var.environment
}

module "database" {
  source             = "./modules/database"
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  db_username        = var.db_username
  db_password        = var.db_password
  env                = var.environment
}
