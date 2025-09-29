resource "aws_security_group" "proxy" {
  name_prefix = "${var.project_name}-proxy-"
  vpc_id      = aws_vpc.central.id

  ingress {
    description = "HTTP from Central VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.central.cidr_block]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.central.cidr_block]
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
    spoke_instance_ip = aws_instance.spoke_web.private_ip
  })
}

resource "aws_instance" "proxy_a" {
  ami                  = data.aws_ami.al2023.id
  instance_type        = var.instance_type
  key_name             = var.key_name
  subnet_id            = aws_subnet.central_private_a.id
  security_groups      = [aws_security_group.proxy.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = base64encode(local.proxy_user_data)

  tags = {
    Name = "${var.project_name}-proxy-a"
    Type = "Proxy"
  }
}

resource "aws_instance" "proxy_c" {
  ami                  = data.aws_ami.al2023.id
  instance_type        = var.instance_type
  key_name             = var.key_name
  subnet_id            = aws_subnet.central_private_c.id
  security_groups      = [aws_security_group.proxy.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

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