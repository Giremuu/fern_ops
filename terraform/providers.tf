
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "fernops-tfstate"
    key            = "terraform.tfstate"
    region         = "eu-west-3"
    dynamodb_table = "fernops-tfstate-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}
