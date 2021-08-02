terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.50"
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
/*
resource "aws_s3_bucket" "log_bucket" {
  bucket = var.transcoding_log_bucket
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
}*/

resource "aws_cloudwatch_log_group" "example" {
  name              = "/aws/lambda/terraform-video-transcoding"
  retention_in_days = 14
}

resource "aws_iam_role" "terraform_transcoding_lambda_role" {
  name = "terraform_transcoding_lambda_role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }]
  })
  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  inline_policy {
    name = "terraform_transcoding_lambda_policy"
    
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Sid = "",
          Effect = "Allow",
          Action = "s3:GetObject",
          Resource = "${aws_s3_bucket.input_bucket.arn}/*"
        },
        {
          Sid = "",
          Effect = "Allow",
          Action = "s3:PutObject",
          Resource = "${aws_s3_bucket.output_bucket.arn}/*"
        },
        {
          Sid = "",
          Effect = "Allow",
          Action = [
            "logs:PutLogEvents",
            "logs:CreateLogStream",
            "logs:CreateLogGroup"
          ],
          Resource = "arn:aws:logs:*:*:*",
        }
      ]
    })
  }
}

data "archive_file" "lambda_transcode_handler" {
  type        = "zip"
  source_file = "${path.module}/data/transcode.py"
  output_path = "${path.module}/files/lambda_function_payload.zip"
}

resource "aws_lambda_layer_version" "ffmpeg_install_layer" {
  layer_name = "ffmpeg_install"
  filename = "${path.module}/data/ffmpeg.zip"
  compatible_runtimes = ["python3.8"]
}

resource "aws_lambda_function" "video_transcoding_lambda" {
  filename      = "${path.module}/files/lambda_function_payload.zip"
  function_name = "terraform-video-transcoding-lambda"
  role          = aws_iam_role.terraform_transcoding_lambda_role.arn
  handler       = "transcode.handler"
  memory_size   = 2240
  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  #source_code_hash = filebase64sha256("lambda_function_payload.zip")

  runtime = "python3.8"

  environment {
    variables = {
      S3_DESTINATION_BUCKET = var.transcoding_output_bucket
      SIGNED_URL_TIMEOUT = 60
    }
  }
}

resource "aws_lambda_permission" "input_allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.video_transcoding_lambda.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.input_bucket.arn
}

resource "aws_s3_bucket_notification" "video_transcoding_lambda" {
  bucket = aws_s3_bucket.input_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.video_transcoding_lambda.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".mkv"
  }

  depends_on = [aws_lambda_permission.input_allow_bucket]
}

