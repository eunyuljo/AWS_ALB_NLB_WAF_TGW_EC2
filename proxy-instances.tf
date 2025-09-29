resource "aws_security_group" "proxy" {
  name_prefix = "${var.project_name}-proxy-"
  vpc_id      = aws_vpc.hub.id

  ingress {
    description = "HTTP from Hub VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.hub.cidr_block]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.hub.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-proxy-sg"
  }
}

locals {
  proxy_user_data = templatefile("${path.module}/proxy-config.tftpl", {
    spoke_1_lb_dns = aws_lb.spoke_1_internal.dns_name
    spoke_2_lb_dns = aws_lb.spoke_2_internal.dns_name
    spoke_3_lb_dns = aws_lb.spoke_3_internal.dns_name
  })
}

resource "aws_instance" "proxy_a" {
  ami             = data.aws_ami.al2023.id
  instance_type   = var.instance_type
  key_name        = var.key_name
  subnet_id       = aws_subnet.hub_private_a.id
  security_groups = [aws_security_group.proxy.id]

  user_data = base64encode(local.proxy_user_data)

  tags = {
    Name = "${var.project_name}-proxy-a"
    Type = "Proxy"
  }
}

resource "aws_instance" "proxy_c" {
  ami             = data.aws_ami.al2023.id
  instance_type   = var.instance_type
  key_name        = var.key_name
  subnet_id       = aws_subnet.hub_private_c.id
  security_groups = [aws_security_group.proxy.id]

  user_data = base64encode(local.proxy_user_data)

  tags = {
    Name = "${var.project_name}-proxy-c"
    Type = "Proxy"
  }
}

resource "aws_lb_target_group_attachment" "proxy_a" {
  target_group_arn = aws_lb_target_group.nlb_to_proxy.arn
  target_id        = aws_instance.proxy_a.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "proxy_c" {
  target_group_arn = aws_lb_target_group.nlb_to_proxy.arn
  target_id        = aws_instance.proxy_c.id
  port             = 8080
}