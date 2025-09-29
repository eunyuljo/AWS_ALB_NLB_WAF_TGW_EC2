# Spoke VPC Security Groups
resource "aws_security_group" "spoke_main" {
  name_prefix = "${var.project_name}-spoke-main-"
  vpc_id      = aws_vpc.spoke.id

  ingress {
    description = "HTTP from Central"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.central_vpc_cidr]
  }

  ingress {
    description = "SSH from Central"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.central_vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-spoke-main-sg"
  }
}



locals {
  spoke_user_data = <<-EOF
#!/bin/bash
# Create simple HTTP server using Python3 (pre-installed on AL2023)
mkdir -p /var/www/html
cat > /var/www/html/server.py << 'PYEOF'
#!/usr/bin/env python3
import http.server
import socketserver
import os
import subprocess

class MyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()

        # Get instance metadata
        try:
            hostname = os.uname().nodename
            instance_id = subprocess.check_output(['curl', '-s', 'http://169.254.169.254/latest/meta-data/instance-id'], timeout=5).decode().strip()
        except:
            hostname = "unknown"
            instance_id = "unknown"

        html = f"""
        <html>
        <head><title>Spoke VPC Web Server</title></head>
        <body>
            <h1>Spoke VPC Web Server</h1>
            <p>Hostname: {hostname}</p>
            <p>Instance ID: {instance_id}</p>
            <p>VPC: ${var.spoke_vpc_cidr}</p>
            <p>Server: Python HTTP Server</p>
        </body>
        </html>
        """
        self.wfile.write(html.encode())

PORT = 80
with socketserver.TCPServer(("", PORT), MyHTTPRequestHandler) as httpd:
    print(f"Server running on port {PORT}")
    httpd.serve_forever()
PYEOF

# Make executable and start
chmod +x /var/www/html/server.py
nohup python3 /var/www/html/server.py > /var/log/simple-http.log 2>&1 &

# Create systemd service for auto-start
cat > /etc/systemd/system/simple-http.service << 'SVCEOF'
[Unit]
Description=Simple HTTP Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/var/www/html
ExecStart=/usr/bin/python3 /var/www/html/server.py
Restart=always

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl enable simple-http.service
systemctl start simple-http.service
EOF


}

# Spoke VPC Instances
resource "aws_instance" "spoke_web" {
  ami                  = data.aws_ami.al2023.id
  instance_type        = var.instance_type
  key_name             = var.key_name
  subnet_id            = aws_subnet.spoke_private.id
  security_groups      = [aws_security_group.spoke_main.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = base64encode(local.spoke_user_data)

  tags = {
    Name = "${var.project_name}-spoke-web"
    Type = "Web"
  }
}






