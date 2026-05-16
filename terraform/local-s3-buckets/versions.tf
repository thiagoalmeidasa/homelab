terraform {
  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = "~> 1.15.0"
    }
  }
  required_version = "~> 1.15.0"
}
