output "url" {
  value = "https://${var.frontend}"
}

output "debug_cert_arn" {
 value = "${length(var.cert_arn)}"
}

