variable "aws_profile" {
  type = string
  default = "default"
  description = "Choose AWS profile credentials"
}
variable "transcoding_input_bucket" {
  type = string
  default = ""
  description = "Bucket used for writing video data in order to be processed"
}

variable "transcoding_output_bucket" {
  type = string
  default = ""
  description = "Bucket used for storing processed video"
}

variable "sse_algorithm" {
  type        = string
  default     = "AES256"
  description = "The server-side encryption algorithm to use. Valid values are `AES256` and `aws:kms`"
}

variable "vpc_id" {
  type = string
  default = ""
  description = "vpc-12a324d"
}
