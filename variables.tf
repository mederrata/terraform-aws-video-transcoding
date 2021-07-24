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
