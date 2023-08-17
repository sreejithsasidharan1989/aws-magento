module "vpc" {
  source       = "github.com/sreejithsasidharan1989/aws-vpc-module"
  project      = var.project
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
  enable_natgw = var.nat_switch
}

module "alb" {
  source      = "github.com/sreejithsasidharan1989/aws-alb-module"
  project     = var.project
  environment = var.environment
  alb_switch  = var.alb_switch
  subnet_ids  = module.vpc.public_subnets
  vpc_id      = module.vpc.vpc_id
  cert_switch = var.cert_switch
  cert_arn    = length(var.cert_arn) == 1 ? aws_acm_certificate.ssl[0].arn : var.cert_arn
}
resource "aws_acm_certificate" "ssl" {
  count                     = length(var.cert_arn) == 1 && tonumber(var.alb_switch) == 1 ? 1 : 0
  domain_name               = var.public-zone
  validation_method         = "DNS"
  subject_alternative_names = ["*.${var.public-zone}"]

  tags = {
    Environment = var.environment
    Project     = var.project
  }
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_route53_record" "ssl" {
  for_each = length(var.cert_arn) == 1 && tonumber(var.alb_switch) == 1 ? {} : {
    for dvo in aws_acm_certificate.ssl[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  name            =  each.value.name
  records         =  [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = tonumber(var.dns_switch) == 0 ? data.aws_route53_zone.public[0].id : aws_route53_zone.public[0].id
}
resource "aws_acm_certificate_validation" "ssl_validate" {
  count                   = length(var.cert_arn) == 1 && tonumber(var.alb_switch) == 1 ? 1 : 0
  certificate_arn         = aws_acm_certificate.ssl[0].arn
  validation_record_fqdns = [for record in aws_route53_record.ssl : record.fqdn]
}
resource "tls_private_key" "key_file" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "aws_key_pair" "mage_key" {
  key_name   = "${var.project}-${var.environment}-mgae_key"
  public_key = tls_private_key.key_file.public_key_openssh
  provisioner "local-exec" {
    command = "echo '${tls_private_key.key_file.private_key_pem}' > ./mykey.pem; chmod 400 ./mykey.pem"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "rm -rf ./mykey.pem"
  }
}
resource "aws_security_group" "backend-sg" {
  name_prefix = "${var.project}-${var.environment}-backend-"
  description = "Allow SSH access from bastion server and MySql access from frontend"
  vpc_id      = module.vpc.vpc_id
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend-sg.id]
  }
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  depends_on = [aws_security_group.frontend-sg]
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name        = "${var.project}-${var.environment}-backend"
    Project     = "${local.common_tags.project}"
    Environment = "${local.common_tags.environment}"
  }
}
resource "aws_security_group_rule" "allow_docker" {
  type                     = "ingress"
  to_port                  = 2377
  from_port                = 0
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.docker-sg.id
  security_group_id        = aws_security_group.backend-sg.id
}

resource "aws_security_group" "frontend-sg" {
  name_prefix = "${var.project}-${var.environment}-frontend-"
  description = "Allow SSH access from all & HTTP access from public"
  vpc_id      = module.vpc.vpc_id
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name        = "${var.project}-${var.environment}-frontend"
    Project     = "${local.common_tags.project}"
    Environment = "${local.common_tags.environment}"
  }
}
resource "aws_security_group" "docker-sg" {
  name_prefix = "${var.project}-${var.environment}-frontend-"
  description = "Allow connection from Docker Swarm"
  vpc_id      = module.vpc.vpc_id
  ingress {
    from_port       = 9200
    to_port         = 9200
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend-sg.id]
  }
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  depends_on = [aws_security_group.backend-sg]
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name        = "${var.project}-${var.environment}-docker"
    Project     = "${local.common_tags.project}"
    Environment = "${local.common_tags.environment}"
  }
}
resource "aws_instance" "frontend-server" {
  ami                    = var.ami_id
  instance_type          = var.instance-type
  key_name               = aws_key_pair.mage_key.key_name
  vpc_security_group_ids = [aws_security_group.frontend-sg.id]
  subnet_id              = module.vpc.public_subnets.0
  tags = {
    Name        = "Frontend-Server"
    Project     = "${local.common_tags.project}"
    Environment = "${local.common_tags.environment}"
  }
  depends_on = [aws_instance.backend, aws_instance.docker, aws_route53_record.docker-server, aws_route53_record.backend-server]
  provisioner "local-exec" {
    command = "ansible-playbook --ask-vault-pass frontend.yml"
  }
}
resource "aws_instance" "backend" {
  ami                    = var.ami_id
  key_name               = aws_key_pair.mage_key.key_name
  instance_type          = var.instance-type
  vpc_security_group_ids = [aws_security_group.backend-sg.id]
  subnet_id              = module.vpc.public_subnets[1]
  tags = {
    Name        = "Backend-Server"
    Project     = "${local.common_tags.project}"
    Environment = "${local.common_tags.environment}"
  }
  provisioner "local-exec" {
    command = "ansible-playbook --ask-vault-pass backend.yml"
  }
}
resource "aws_instance" "docker" {
  ami                    = var.ami_id
  instance_type          = var.instance-type
  key_name               = aws_key_pair.mage_key.key_name
  vpc_security_group_ids = [aws_security_group.docker-sg.id]
  subnet_id              = module.vpc.public_subnets[1]
  tags = {
    Name        = "Docker-Worker"
    Project     = "${local.common_tags.project}"
    Environment = "${local.common_tags.environment}"
  }
  depends_on = [aws_instance.backend]
  provisioner "local-exec" {
    command = "ansible-playbook --ask-vault-pass docker.yml"
  }
}
resource "aws_lb_target_group_attachment" "frontend_tg" {
  target_group_arn = module.alb.tg_arn
  target_id        = aws_instance.frontend-server.id
  port             = 80
}
resource "aws_route53_zone" "private" {
  name = var.private-zone
  vpc {
    vpc_id = module.vpc.vpc_id
  }
}
resource "aws_route53_zone" "public" {
  count = var.dns_switch ? 1 : 0
  name  = var.public-zone
}
resource "aws_route53_record" "frontend-servers" {
  count   = var.alb_switch == 0 && var.dns_switch == 0 ? 1 : 0
  zone_id = data.aws_route53_zone.public[0].id
  name    = var.frontend
  type    = "A"
  ttl     = "300"
  records = [aws_instance.frontend-server.public_ip]
}
resource "aws_route53_record" "alb-cname" {
  count   = var.alb_switch && var.dns_switch ? 1 : 0
  zone_id = aws_route53_zone.public[0].id
  name    = var.frontend
  type    = "CNAME"
  ttl     = "300"
  records = [module.alb.dns_name]
}
resource "aws_route53_record" "alb-off" {
  count   = var.dns_switch == 1 && var.alb_switch == 0 ? 1 : 0
  zone_id = aws_route53_zone.public[0].id
  name    = var.frontend
  type    = "A"
  ttl     = "300"
  records = [aws_instance.frontend-server.public_ip]
}
resource "aws_route53_record" "alb-on" {
  count   = var.dns_switch == 0 && var.alb_switch == 1 ? 1 : 0
  zone_id = data.aws_route53_zone.public[0].id
  name    = var.frontend
  type    = "CNAME"
  ttl     = "300"
  records = [module.alb.dns_name]
}
resource "aws_route53_record" "backend-server" {
  zone_id = resource.aws_route53_zone.private.id
  name    = var.backend
  type    = "A"
  ttl     = "300"
  records = [aws_instance.backend.private_ip]
}

resource "aws_route53_record" "docker-server" {
  zone_id = resource.aws_route53_zone.private.id
  name    = var.docker
  type    = "A"
  ttl     = "300"
  records = [aws_instance.docker.private_ip]
}
