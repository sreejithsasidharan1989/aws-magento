data "aws_route53_zone" "public" {
  name         = "backtracker.tech"
  private_zone = false
}
