resource "aws_vpc" "hub" {
  cidr_block           = var.hub_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-hub-vpc"
    Type = "Hub"
  }
}

resource "aws_internet_gateway" "hub" {
  vpc_id = aws_vpc.hub.id

  tags = {
    Name = "${var.project_name}-hub-igw"
  }
}

resource "aws_subnet" "hub_public_a" {
  vpc_id = aws_vpc.hub.id

  cidr_block              = "10.0.0.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-hub-public-a"
    Type = "Public"
  }
}

resource "aws_subnet" "hub_public_c" {
  vpc_id = aws_vpc.hub.id

  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-hub-public-c"
    Type = "Public"
  }
}

resource "aws_subnet" "hub_private_a" {
  vpc_id = aws_vpc.hub.id

  cidr_block        = "10.0.10.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "${var.project_name}-hub-private-a"
    Type = "Private"
  }
}

resource "aws_subnet" "hub_private_c" {
  vpc_id = aws_vpc.hub.id

  cidr_block        = "10.0.11.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "${var.project_name}-hub-private-c"
    Type = "Private"
  }
}

resource "aws_route_table" "hub_public" {
  vpc_id = aws_vpc.hub.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hub.id
  }

  tags = {
    Name = "${var.project_name}-hub-public-rt"
  }
}

resource "aws_route_table" "hub_private" {
  vpc_id = aws_vpc.hub.id

  tags = {
    Name = "${var.project_name}-hub-private-rt"
  }
}

resource "aws_route_table_association" "hub_public_a" {
  subnet_id      = aws_subnet.hub_public_a.id
  route_table_id = aws_route_table.hub_public.id
}

resource "aws_route_table_association" "hub_public_c" {
  subnet_id      = aws_subnet.hub_public_c.id
  route_table_id = aws_route_table.hub_public.id
}

resource "aws_route_table_association" "hub_private_a" {
  subnet_id      = aws_subnet.hub_private_a.id
  route_table_id = aws_route_table.hub_private.id
}

resource "aws_route_table_association" "hub_private_c" {
  subnet_id      = aws_subnet.hub_private_c.id
  route_table_id = aws_route_table.hub_private.id
}

resource "aws_eip" "nat_a" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip-a"
  }

  depends_on = [aws_internet_gateway.hub]
}

resource "aws_eip" "nat_c" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip-c"
  }

  depends_on = [aws_internet_gateway.hub]
}

resource "aws_nat_gateway" "hub_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.hub_public_a.id

  tags = {
    Name = "${var.project_name}-nat-gw-a"
  }

  depends_on = [aws_internet_gateway.hub]
}

resource "aws_nat_gateway" "hub_c" {
  allocation_id = aws_eip.nat_c.id
  subnet_id     = aws_subnet.hub_public_c.id

  tags = {
    Name = "${var.project_name}-nat-gw-c"
  }

  depends_on = [aws_internet_gateway.hub]
}

resource "aws_route" "hub_private_nat" {
  route_table_id         = aws_route_table.hub_private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.hub_a.id
}