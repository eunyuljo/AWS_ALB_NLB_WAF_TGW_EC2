resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-alb-"
  vpc_id      = aws_vpc.central.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

resource "aws_lb" "internet_facing" {
  name               = "${var.project_name}-internet-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.central_public_a.id, aws_subnet.central_public_c.id]

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-internet-alb"
  }
}


resource "aws_lb" "internal" {
  name               = "${var.project_name}-internal-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = [aws_subnet.central_private_a.id, aws_subnet.central_private_c.id]

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-internal-nlb"
  }
}


resource "aws_lb_target_group" "alb_to_nlb" {
  name        = "${var.project_name}-alb-to-nlb"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.central.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-alb-to-nlb-tg"
  }
}

resource "aws_lb_target_group" "nlb_to_proxy" {
  name     = "${var.project_name}-nlb-to-proxy"
  port     = 8080
  protocol = "TCP"
  vpc_id   = aws_vpc.central.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    port                = "8080"
    protocol            = "HTTP"
    path                = "/health"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-nlb-to-proxy-tg"
  }
}

resource "aws_lb_listener" "alb" {
  load_balancer_arn = aws_lb.internet_facing.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_to_nlb.arn
  }
}

resource "aws_lb_listener" "nlb" {
  load_balancer_arn = aws_lb.internal.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_to_proxy.arn
  }
}

data "aws_network_interface" "nlb_eni_a" {
  depends_on = [aws_lb.internal]

  filter {
    name   = "description"
    values = ["ELB ${aws_lb.internal.arn_suffix}"]
  }

  filter {
    name   = "availability-zone"
    values = [var.availability_zones[0]]
  }

  filter {
    name   = "status"
    values = ["in-use"]
  }
}

data "aws_network_interface" "nlb_eni_c" {
  depends_on = [aws_lb.internal]

  filter {
    name   = "description"
    values = ["ELB ${aws_lb.internal.arn_suffix}"]
  }

  filter {
    name   = "availability-zone"
    values = [var.availability_zones[1]]
  }

  filter {
    name   = "status"
    values = ["in-use"]
  }
}

resource "aws_lb_target_group_attachment" "alb_to_nlb_a" {
  target_group_arn = aws_lb_target_group.alb_to_nlb.arn
  target_id        = data.aws_network_interface.nlb_eni_a.private_ip
  port             = 80
}

resource "aws_lb_target_group_attachment" "alb_to_nlb_c" {
  target_group_arn = aws_lb_target_group.alb_to_nlb.arn
  target_id        = data.aws_network_interface.nlb_eni_c.private_ip
  port             = 80
}

