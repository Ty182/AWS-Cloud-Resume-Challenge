terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.25.0"
    }
  }
  backend "s3" {
    bucket = "terraformstate-tyler"
    key    = "crc"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      "env"     = "production"
      "project" = "cloud_resume_challenge"
    }
  }
}
