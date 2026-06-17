provider "resend" {
  api_key = var.resend_api_key
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
