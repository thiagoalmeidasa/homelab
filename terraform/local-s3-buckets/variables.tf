variable "s3_region" {
  type        = string
  description = "Versity S3 signing region"
  default     = "us-east-1"
}

variable "s3_endpoint" {
  type        = string
  description = "Versity S3 endpoint"
  default     = "https://s3.home399.thiagoalmeida.xyz"
}

variable "access_key" {
  type        = string
  description = "Versity access key"
  sensitive   = true
}

variable "secret_key" {
  type        = string
  description = "Versity secret key"
  sensitive   = true
}
