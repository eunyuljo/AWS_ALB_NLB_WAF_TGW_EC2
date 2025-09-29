# Spoke VPC Security Groups
resource "aws_security_group" "spoke_1_main" {
  name_prefix = "${var.project_name}-spoke-1-main-"
  vpc_id      = aws_vpc.spoke_1.id

  ingress {
    description = "HTTP from Hub"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.hub_vpc_cidr]
  }

  ingress {
    description = "SSH from Hub"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.hub_vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-spoke-1-main-sg"
  }
}

resource "aws_security_group" "spoke_2_main" {
  name_prefix = "${var.project_name}-spoke-2-main-"
  vpc_id      = aws_vpc.spoke_2.id

  ingress {
    description = "HTTP from Hub"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.hub_vpc_cidr]
  }

  ingress {
    description = "SSH from Hub"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.hub_vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-spoke-2-main-sg"
  }
}

resource "aws_security_group" "spoke_3_main" {
  name_prefix = "${var.project_name}-spoke-3-main-"
  vpc_id      = aws_vpc.spoke_3.id

  ingress {
    description = "HTTP from Hub"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.hub_vpc_cidr]
  }

  ingress {
    description = "SSH from Hub"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.hub_vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-spoke-3-main-sg"
  }
}

locals {
  spoke_1_user_data = <<-EOF
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd

echo "<h1>Spoke VPC 1 Web Server</h1>" > /var/www/html/index.html
echo "<p>Hostname: $(hostname)</p>" >> /var/www/html/index.html
echo "<p>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>" >> /var/www/html/index.html
echo "<p>VPC: 10.1.0.0/16</p>" >> /var/www/html/index.html
EOF

  spoke_2_user_data = <<-EOF
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd

echo "<h1>Spoke VPC 2 Web Server</h1>" > /var/www/html/index.html
echo "<p>Hostname: $(hostname)</p>" >> /var/www/html/index.html
echo "<p>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>" >> /var/www/html/index.html
echo "<p>VPC: 10.2.0.0/16</p>" >> /var/www/html/index.html
EOF

  spoke_3_user_data = <<-EOF
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd

echo "<h1>Spoke VPC 3 Web Server</h1>" > /var/www/html/index.html
echo "<p>Hostname: $(hostname)</p>" >> /var/www/html/index.html
echo "<p>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>" >> /var/www/html/index.html
echo "<p>VPC: 10.3.0.0/16</p>" >> /var/www/html/index.html
EOF
}

# Spoke VPC Instances
resource "aws_instance" "spoke_1_web" {
  ami             = data.aws_ami.al2023.id
  instance_type   = var.instance_type
  key_name        = var.key_name
  subnet_id       = aws_subnet.spoke_1_main.id
  security_groups = [aws_security_group.spoke_1_main.id]

  user_data = base64encode(local.spoke_1_user_data)

  tags = {
    Name = "${var.project_name}-spoke-1-web"
    Type = "Web"
  }
}

resource "aws_instance" "spoke_2_web" {
  ami             = data.aws_ami.al2023.id
  instance_type   = var.instance_type
  key_name        = var.key_name
  subnet_id       = aws_subnet.spoke_2_main.id
  security_groups = [aws_security_group.spoke_2_main.id]

  user_data = base64encode(local.spoke_2_user_data)

  tags = {
    Name = "${var.project_name}-spoke-2-web"
    Type = "Web"
  }
}

resource "aws_instance" "spoke_3_web" {
  ami             = data.aws_ami.al2023.id
  instance_type   = var.instance_type
  key_name        = var.key_name
  subnet_id       = aws_subnet.spoke_3_main.id
  security_groups = [aws_security_group.spoke_3_main.id]

  user_data = base64encode(local.spoke_3_user_data)

  tags = {
    Name = "${var.project_name}-spoke-3-web"
    Type = "Web"
  }
}

# Spoke VPC Load Balancers
resource "aws_lb" "spoke_1_internal" {
  name               = "${var.project_name}-spoke-1-ilb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.spoke_1_main.id]
  subnets            = [aws_subnet.spoke_1_main.id, aws_subnet.spoke_1_private.id]

  tags = {
    Name = "${var.project_name}-spoke-1-ilb"
  }
}

resource "aws_lb" "spoke_2_internal" {
  name               = "${var.project_name}-spoke-2-ilb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.spoke_2_main.id]
  subnets            = [aws_subnet.spoke_2_main.id, aws_subnet.spoke_2_private.id]

  tags = {
    Name = "${var.project_name}-spoke-2-ilb"
  }
}

resource "aws_lb" "spoke_3_internal" {
  name               = "${var.project_name}-spoke-3-ilb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.spoke_3_main.id]
  subnets            = [aws_subnet.spoke_3_main.id, aws_subnet.spoke_3_private.id]

  tags = {
    Name = "${var.project_name}-spoke-3-ilb"
  }
}

# Target Groups
resource "aws_lb_target_group" "spoke_1_web" {
  name     = "${var.project_name}-spoke-1-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.spoke_1.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-spoke-1-web-tg"
  }
}

resource "aws_lb_target_group" "spoke_2_web" {
  name     = "${var.project_name}-spoke-2-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.spoke_2.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-spoke-2-web-tg"
  }
}

resource "aws_lb_target_group" "spoke_3_web" {
  name     = "${var.project_name}-spoke-3-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.spoke_3.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-spoke-3-web-tg"
  }
}

# Load Balancer Listeners
resource "aws_lb_listener" "spoke_1_web" {
  load_balancer_arn = aws_lb.spoke_1_internal.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.spoke_1_web.arn
  }
}

resource "aws_lb_listener" "spoke_2_web" {
  load_balancer_arn = aws_lb.spoke_2_internal.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.spoke_2_web.arn
  }
}

resource "aws_lb_listener" "spoke_3_web" {
  load_balancer_arn = aws_lb.spoke_3_internal.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.spoke_3_web.arn
  }
}

# Target Group Attachments
resource "aws_lb_target_group_attachment" "spoke_1_web" {
  target_group_arn = aws_lb_target_group.spoke_1_web.arn
  target_id        = aws_instance.spoke_1_web.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "spoke_2_web" {
  target_group_arn = aws_lb_target_group.spoke_2_web.arn
  target_id        = aws_instance.spoke_2_web.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "spoke_3_web" {
  target_group_arn = aws_lb_target_group.spoke_3_web.arn
  target_id        = aws_instance.spoke_3_web.id
  port             = 80
}