variable "resend_api_key" {
  type        = string
  description = "Resend API key (from https://resend.com/api-keys)"
  sensitive   = true
}

variable "cloudflare_api_token" {
  type        = string
  description = "Cloudflare API token with DNS edit permission"
  sensitive   = true
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare zone ID for thiagoalmeida.xyz"
}

variable "sending_domain" {
  type        = string
  description = "Subdomain used as the mail sending identity"
  default     = "mail.thiagoalmeida.xyz"
}
