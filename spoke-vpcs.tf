resource "aws_vpc" "spoke_1" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-spoke-vpc-1"
    Type = "Spoke"
  }
}

resource "aws_vpc" "spoke_2" {
  cidr_block           = "10.2.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-spoke-vpc-2"
    Type = "Spoke"
  }
}

resource "aws_vpc" "spoke_3" {
  cidr_block           = "10.3.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-spoke-vpc-3"
    Type = "Spoke"
  }
}

# Spoke VPC 1 Subnet
resource "aws_subnet" "spoke_1_main" {
  vpc_id            = aws_vpc.spoke_1.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "${var.project_name}-spoke-1-main"
    Type = "Main"
  }
}

resource "aws_subnet" "spoke_1_private" {
  vpc_id            = aws_vpc.spoke_1.id
  cidr_block        = "10.1.10.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "${var.project_name}-spoke-1-private"
    Type = "Private"
  }
}

# Spoke VPC 2 Subnet
resource "aws_subnet" "spoke_2_main" {
  vpc_id            = aws_vpc.spoke_2.id
  cidr_block        = "10.2.1.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "${var.project_name}-spoke-2-main"
    Type = "Main"
  }
}

resource "aws_subnet" "spoke_2_private" {
  vpc_id            = aws_vpc.spoke_2.id
  cidr_block        = "10.2.10.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "${var.project_name}-spoke-2-private"
    Type = "Private"
  }
}

# Spoke VPC 3 Subnet
resource "aws_subnet" "spoke_3_main" {
  vpc_id            = aws_vpc.spoke_3.id
  cidr_block        = "10.3.1.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "${var.project_name}-spoke-3-main"
    Type = "Main"
  }
}

resource "aws_subnet" "spoke_3_private" {
  vpc_id            = aws_vpc.spoke_3.id
  cidr_block        = "10.3.10.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "${var.project_name}-spoke-3-private"
    Type = "Private"
  }
}


# Spoke VPC 1 Route Tables
resource "aws_route_table" "spoke_1_main" {
  vpc_id = aws_vpc.spoke_1.id

  tags = {
    Name = "${var.project_name}-spoke-1-main-rt"
  }
}

resource "aws_route_table" "spoke_1_private" {
  vpc_id = aws_vpc.spoke_1.id

  tags = {
    Name = "${var.project_name}-spoke-1-private-rt"
  }
}

# Spoke VPC 2 Route Tables
resource "aws_route_table" "spoke_2_main" {
  vpc_id = aws_vpc.spoke_2.id

  tags = {
    Name = "${var.project_name}-spoke-2-main-rt"
  }
}

resource "aws_route_table" "spoke_2_private" {
  vpc_id = aws_vpc.spoke_2.id

  tags = {
    Name = "${var.project_name}-spoke-2-private-rt"
  }
}

# Spoke VPC 3 Route Tables
resource "aws_route_table" "spoke_3_main" {
  vpc_id = aws_vpc.spoke_3.id

  tags = {
    Name = "${var.project_name}-spoke-3-main-rt"
  }
}

resource "aws_route_table" "spoke_3_private" {
  vpc_id = aws_vpc.spoke_3.id

  tags = {
    Name = "${var.project_name}-spoke-3-private-rt"
  }
}

# Spoke VPC 1 Route Table Associations
resource "aws_route_table_association" "spoke_1_main" {
  subnet_id      = aws_subnet.spoke_1_main.id
  route_table_id = aws_route_table.spoke_1_main.id
}

resource "aws_route_table_association" "spoke_1_private" {
  subnet_id      = aws_subnet.spoke_1_private.id
  route_table_id = aws_route_table.spoke_1_private.id
}

# Spoke VPC 2 Route Table Associations
resource "aws_route_table_association" "spoke_2_main" {
  subnet_id      = aws_subnet.spoke_2_main.id
  route_table_id = aws_route_table.spoke_2_main.id
}

resource "aws_route_table_association" "spoke_2_private" {
  subnet_id      = aws_subnet.spoke_2_private.id
  route_table_id = aws_route_table.spoke_2_private.id
}

# Spoke VPC 3 Route Table Associations
resource "aws_route_table_association" "spoke_3_main" {
  subnet_id      = aws_subnet.spoke_3_main.id
  route_table_id = aws_route_table.spoke_3_main.id
}

resource "aws_route_table_association" "spoke_3_private" {
  subnet_id      = aws_subnet.spoke_3_private.id
  route_table_id = aws_route_table.spoke_3_private.id
}

# Spoke VPC 1 Routes to Transit Gateway
resource "aws_route" "spoke_1_main_to_tgw" {
  route_table_id         = aws_route_table.spoke_1_main.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.main.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.spoke_1]
}

# Spoke VPC 2 Routes to Transit Gateway
resource "aws_route" "spoke_2_main_to_tgw" {
  route_table_id         = aws_route_table.spoke_2_main.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.main.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.spoke_2]
}

# Spoke VPC 3 Routes to Transit Gateway
resource "aws_route" "spoke_3_main_to_tgw" {
  route_table_id         = aws_route_table.spoke_3_main.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.main.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.spoke_3]
}