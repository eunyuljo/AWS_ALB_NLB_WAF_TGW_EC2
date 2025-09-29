resource "aws_vpc" "central" {
  cidr_block           = var.central_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-central-vpc"
    Type = "Central"
  }
}

resource "aws_internet_gateway" "central" {
  vpc_id = aws_vpc.central.id

  tags = {
    Name = "${var.project_name}-central-igw"
  }
}

resource "aws_subnet" "central_public_a" {
  vpc_id = aws_vpc.central.id

  cidr_block              = "10.0.0.0/24"
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-central-public-a"
    Type = "Public"
  }
}

resource "aws_subnet" "central_public_c" {
  vpc_id = aws_vpc.central.id

  cidr_block              = "10.0.1.0/24"
  availability_zone       = var.availability_zones[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-central-public-c"
    Type = "Public"
  }
}

resource "aws_subnet" "central_private_a" {
  vpc_id = aws_vpc.central.id

  cidr_block        = "10.0.10.0/24"
  availability_zone = var.availability_zones[0]

  tags = {
    Name = "${var.project_name}-central-private-a"
    Type = "Private"
  }
}

resource "aws_subnet" "central_private_c" {
  vpc_id = aws_vpc.central.id

  cidr_block        = "10.0.11.0/24"
  availability_zone = var.availability_zones[1]

  tags = {
    Name = "${var.project_name}-central-private-c"
    Type = "Private"
  }
}

resource "aws_route_table" "central_public" {
  vpc_id = aws_vpc.central.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.central.id
  }

  tags = {
    Name = "${var.project_name}-central-public-rt"
  }
}

resource "aws_route_table" "central_private_a" {
  vpc_id = aws_vpc.central.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.central_a.id
  }

  tags = {
    Name = "${var.project_name}-central-private-a-rt"
  }
}

resource "aws_route_table" "central_private_c" {
  vpc_id = aws_vpc.central.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.central_c.id
  }

  tags = {
    Name = "${var.project_name}-central-private-c-rt"
  }
}

resource "aws_route_table_association" "central_public_a" {
  subnet_id      = aws_subnet.central_public_a.id
  route_table_id = aws_route_table.central_public.id
}

resource "aws_route_table_association" "central_public_c" {
  subnet_id      = aws_subnet.central_public_c.id
  route_table_id = aws_route_table.central_public.id
}

resource "aws_route_table_association" "central_private_a" {
  subnet_id      = aws_subnet.central_private_a.id
  route_table_id = aws_route_table.central_private_a.id
}

resource "aws_route_table_association" "central_private_c" {
  subnet_id      = aws_subnet.central_private_c.id
  route_table_id = aws_route_table.central_private_c.id
}

resource "aws_eip" "nat_a" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip-a"
  }

  depends_on = [aws_internet_gateway.central]
}

resource "aws_eip" "nat_c" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip-c"
  }

  depends_on = [aws_internet_gateway.central]
}

resource "aws_nat_gateway" "central_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.central_public_a.id

  tags = {
    Name = "${var.project_name}-nat-gw-a"
  }

  depends_on = [aws_internet_gateway.central]
}

resource "aws_nat_gateway" "central_c" {
  allocation_id = aws_eip.nat_c.id
  subnet_id     = aws_subnet.central_public_c.id

  tags = {
    Name = "${var.project_name}-nat-gw-c"
  }

  depends_on = [aws_internet_gateway.central]
}

