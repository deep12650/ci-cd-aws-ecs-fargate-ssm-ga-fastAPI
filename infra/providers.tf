terraform {
  required_version = ">= 1.6.0"

  # Recommended: configure an S3 backend for remote state & locking
  # backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

provider "aws" {
  region = var.region
}
