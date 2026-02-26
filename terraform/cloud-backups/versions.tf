terraform {
  required_version = ">= 1.0.0"
  required_providers {
    b2 = {
      source  = "Backblaze/b2"
      version = "0.12.1"
    }
  }
}
