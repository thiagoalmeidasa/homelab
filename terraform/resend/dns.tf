resource "cloudflare_dns_record" "dkim" {
  zone_id = var.cloudflare_zone_id
  name    = "resend._domainkey.mail"
  type    = "TXT"
  content = one([for r in resend_domain.mail.records : r.value if r.record == "DKIM"])
  ttl     = 3600
}

resource "cloudflare_dns_record" "bounce_mx" {
  zone_id  = var.cloudflare_zone_id
  name     = "send.mail"
  type     = "MX"
  content  = one([for r in resend_domain.mail.records : r.value if r.type == "MX"])
  priority = 10
  ttl      = 3600
}

resource "cloudflare_dns_record" "bounce_spf" {
  zone_id = var.cloudflare_zone_id
  name    = "send.mail"
  type    = "TXT"
  content = one([for r in resend_domain.mail.records : r.value if r.type == "TXT" && r.record == "SPF"])
  ttl     = 3600
}

resource "cloudflare_dns_record" "spf" {
  zone_id = var.cloudflare_zone_id
  name    = var.sending_domain
  type    = "TXT"
  content = "v=spf1 include:spf.resend.com ~all"
  ttl     = 3600
}

resource "cloudflare_dns_record" "dmarc" {
  zone_id = var.cloudflare_zone_id
  name    = "_dmarc.${var.sending_domain}"
  type    = "TXT"
  content = "v=DMARC1; p=none; rua=mailto:thiagoalmeidasa@gmail.com"
  ttl     = 3600
}
