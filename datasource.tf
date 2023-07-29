data "aws_route53_zone" "public" {
  count        = var.dns_switch ? 0 : 1
  name         = var.public-zone
  private_zone = false
}
