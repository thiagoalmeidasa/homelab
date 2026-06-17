resource "resend_domain" "mail" {
  name   = var.sending_domain
  region = "eu-west-1"
}

resource "resend_domain_verification" "mail" {
  domain_id = resend_domain.mail.id

  depends_on = [
    cloudflare_dns_record.dkim,
    cloudflare_dns_record.bounce_mx,
    cloudflare_dns_record.bounce_spf,
    cloudflare_dns_record.spf,
    cloudflare_dns_record.dmarc,
  ]
}

resource "resend_api_key" "smtp_relay" {
  name = "homelab-smtp-relay"
}

output "smtp_password" {
  description = "Resend API key to use as SMTP password in the smtp-relay secret"
  value       = resend_api_key.smtp_relay.token
  sensitive   = true
}

output "domain_status" {
  description = "Resend domain verification status"
  value       = resend_domain.mail.status
}
