terraform {
  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = "~> 3.38.0"
    }
  }
  required_version = "~> 1.15.0"
}
