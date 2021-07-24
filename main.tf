terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

resource "aws_s3_bucket" "source_bucket" {
  bucket = var.transcoding_source_bucket
  acl = "private"

  tags = {
    Name = "ExampleAppServerInstance"
  }
}

