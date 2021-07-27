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

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = var.sse_algorithm
      }
    }
  }
  tags = {
    Name = "terraform-video-transcoding"
    Terraform = "true"
    Anisible = "false"
  }
}

resource "aws_s3_bucket" "output_bucket" {
  bucket = var.transcoding_output_bucket
  acl = "private"


  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = var.sse_algorithm
      }
    }
  }

  tags = {
    Name = "terraform-video-transcoding"
    Terraform = "true"
    Anisible = "false"
  }
}

resource "aws_iam_role" "terraform_transcoding_role" {
  name = "terraform_transcoding_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "VisualEditor0",
        "Effect": "Allow",
        "Action": "s3:GetObject",
        "Resource": "${aws_s3_bucket.input_bucket.arn}/*"
      },
      {
        "Sid": "VisualEditor1",
        "Effect": "Allow",
        "Action": "s3:PutObject",
        "Resource": "${aws_s3_bucket.output_bucket.arn}/*"
      },
      {
        "Sid": "VisualEditor2",
        "Effect": "Allow",
        "Action": [
          "logs:PutLogEvents",
          "logs:CreateLogStream",
          "logs:CreateLogGroup"
        ],
        "Resource": "*"
      }
    ]
  })

  tags = {
    Terraform = "true"
    Anisible = "false"
  }
}

