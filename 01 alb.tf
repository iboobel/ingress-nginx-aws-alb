resource "aws_acm_certificate" "default" {
  domain_name       = "example.com"
  validation_method = "DNS"
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"

  name = "example-alb"

  load_balancer_type = "application"

  enable_deletion_protection = true

  vpc_id             = data.vpc.vpc_id
  subnets            = data.vpc.aws_subnet_public_ids

  target_groups = {
    ingress-gateway = {
      name_prefix      = "gw"
      protocol         = "HTTP"
      port             = 32430
      target_type      = "instance"
      create_attachment = false
    }
  }

  listeners = {
    http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = aws_acm_certificate.default.arn
      additional_certificate_arns = aws_acm_certificate.default.arn

      forward = {
        target_group_key = "ingress-gateway"
      }
    }
  }  
}

resource "aws_security_group_rule" "allow_http" {

  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]

  security_group_id = module.alb.security_group_id
}

resource "aws_security_group_rule" "allow_https" {

  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]

  security_group_id = module.alb.security_group_id
}

resource "aws_security_group_rule" "allow_egress" {

  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]

  security_group_id = module.alb.security_group_id
}