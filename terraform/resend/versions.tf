terraform {
  required_version = "~> 1.15.0"
  required_providers {
    resend = {
      source  = "y0n0zawa/resend"
      version = "1.0.1"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
}
