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
  default_tags {
    tags = {
      Terraform = "true"
      Anisible = "false"
    }
  }
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
}

resource "aws_lambda_layer_version" "ffmpeg_install" {
  layer_name = "ffmpeg_install"
  compatible_runtimes = ["python3.8"]
}

resource "aws_lambda_function" "video_transcoding_lambda" {
  filename      = "lambda_function_payload.zip"
  function_name = "terraform-video-transcoding-lambda"
  role          = aws_iam_role.terraform_transcoding_role.arn
  handler       = "index.test"
  memory_size   = 2240
  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  # source_code_hash = filebase64sha256("lambda_function_payload.zip")

  runtime = "python3.8"

  environment {
    variables = {
      foo = "bar"
    }
  }
}

resource "aws_sns_topic" "input_topic" {
  name = "terraform-s3-video-transcoding-topic"

  policy = jsonencode({
    "Version":"2012-10-17",
    "Statement":[{
        "Effect": "Allow",
        "Principal": { "Service": "s3.amazonaws.com" },
        "Action": "SNS:Publish",
        "Resource": "arn:aws:sns:*:*:s3-event-notification-topic",
        "Condition":{
            "ArnLike":{"aws:SourceArn":"${aws_s3_bucket.input_bucket.arn}"}
        }
    }]
  })
}


resource "aws_s3_bucket_notification" "input_bucket_notification" {
  bucket = aws_s3_bucket.input_bucket.id

  topic {
    topic_arn     = aws_sns_topic.input_topic.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".log"
  }
}