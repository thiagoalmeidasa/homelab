variable "minio_region" {
  type        = string
  description = "Default MINIO region"
  default     = "us-east-1"
}

variable "minio_server" {
  type        = string
  description = "Default MINIO host and port"
  default     = "s3.home399.thiagoalmeida.xyz"
}

variable "minio_user" {
  type        = string
  description = "MINIO user"
  default     = "minio-root"
}

variable "minio_password" {
  type        = string
  description = "MINIO password"
  sensitive   = true
}
