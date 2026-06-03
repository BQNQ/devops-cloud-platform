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
  vpc_name = var.vpc_name
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
}
