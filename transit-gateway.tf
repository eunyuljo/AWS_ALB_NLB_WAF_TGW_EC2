resource "aws_ec2_transit_gateway" "main" {
  description                     = "Hub-Spoke Transit Gateway"
  amazon_side_asn                = 64512
  auto_accept_shared_attachments = "enable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"

  tags = {
    Name = "${var.project_name}-tgw"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "hub" {
  subnet_ids         = [aws_subnet.hub_private_a.id, aws_subnet.hub_private_c.id]
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = aws_vpc.hub.id

  tags = {
    Name = "${var.project_name}-tgw-attachment-hub"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "spoke_1" {
  subnet_ids         = [aws_subnet.spoke_1_private.id]
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = aws_vpc.spoke_1.id

  tags = {
    Name = "${var.project_name}-tgw-attachment-spoke-1"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "spoke_2" {
  subnet_ids         = [aws_subnet.spoke_2_private.id]
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = aws_vpc.spoke_2.id

  tags = {
    Name = "${var.project_name}-tgw-attachment-spoke-2"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "spoke_3" {
  subnet_ids         = [aws_subnet.spoke_3_private.id]
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = aws_vpc.spoke_3.id

  tags = {
    Name = "${var.project_name}-tgw-attachment-spoke-3"
  }
}

resource "aws_route" "hub_to_spoke_1" {
  route_table_id         = aws_route_table.hub_private.id
  destination_cidr_block = "10.1.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.main.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.hub]
}

resource "aws_route" "hub_to_spoke_2" {
  route_table_id         = aws_route_table.hub_private.id
  destination_cidr_block = "10.2.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.main.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.hub]
}

resource "aws_route" "hub_to_spoke_3" {
  route_table_id         = aws_route_table.hub_private.id
  destination_cidr_block = "10.3.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.main.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.hub]
}

resource "aws_route" "spoke_1_to_hub" {
  route_table_id         = aws_route_table.spoke_1_private.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.main.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.spoke_1]
}

resource "aws_route" "spoke_2_to_hub" {
  route_table_id         = aws_route_table.spoke_2_private.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.main.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.spoke_2]
}

resource "aws_route" "spoke_3_to_hub" {
  route_table_id         = aws_route_table.spoke_3_private.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.main.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.spoke_3]
}