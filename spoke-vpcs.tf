resource "aws_vpc" "spoke" {
  cidr_block           = var.spoke_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-spoke-vpc"
    Type = "Spoke"
  }
}


resource "aws_subnet" "spoke_main" {
  vpc_id            = aws_vpc.spoke.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = var.availability_zones[0]

  tags = {
    Name = "${var.project_name}-spoke-main"
    Type = "Main"
  }
}

resource "aws_subnet" "spoke_private" {
  vpc_id            = aws_vpc.spoke.id
  cidr_block        = "10.1.10.0/24"
  availability_zone = var.availability_zones[1]

  tags = {
    Name = "${var.project_name}-spoke-private"
    Type = "Private"
  }
}



resource "aws_route_table" "spoke_main" {
  vpc_id = aws_vpc.spoke.id

  tags = {
    Name = "${var.project_name}-spoke-main-rt"
  }
}

resource "aws_route_table" "spoke_private" {
  vpc_id = aws_vpc.spoke.id

  tags = {
    Name = "${var.project_name}-spoke-private-rt"
  }
}


resource "aws_route_table_association" "spoke_main" {
  subnet_id      = aws_subnet.spoke_main.id
  route_table_id = aws_route_table.spoke_main.id
}

resource "aws_route_table_association" "spoke_private" {
  subnet_id      = aws_subnet.spoke_private.id
  route_table_id = aws_route_table.spoke_private.id
}



