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
  profile = var.aws_profile
  region  = "us-west-2"
}

resource "aws_s3_bucket" "input_bucket" {
  bucket = var.transcoding_input_bucket
  acl = "private"

  tags = {
    Name = "ExampleAppServerInstance"
  }
}

resource "aws_s3_bucket" "output_bucket" {
  bucket = var.transcoding_output_bucket
  acl = "private"

  tags = {
    Name = "ExampleAppServerInstance"
  }
}

