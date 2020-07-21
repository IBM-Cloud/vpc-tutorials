resource "tls_private_key" "ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P521"
}

variable ca_cert_validity_period_days {
  default     = 365
  description = "ca certificate validity, in days"
}

variable ca_cert_early_renewal_days {
  default     = 180
  description = "ca early certificate renewal, in days"
}


resource "tls_self_signed_cert" "ca" {
  key_algorithm         = "RSA"
  private_key_pem       = tls_private_key.ca.private_key_pem
  validity_period_hours = var.ca_cert_validity_period_days * 24
  early_renewal_hours   = var.ca_cert_early_renewal_days * 24
  is_ca_certificate     = true

  allowed_uses = ["cert_signing"]

  subject {
    common_name = "openvpn ca"
  }
}