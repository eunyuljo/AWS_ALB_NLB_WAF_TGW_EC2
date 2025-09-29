resource "aws_ec2_transit_gateway" "main" {
  description                     = "Hub-Spoke Transit Gateway"
  amazon_side_asn                 = 64512
  auto_accept_shared_attachments  = "enable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"

  tags = {
    Name = "${var.project_name}-tgw"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "central" {
  subnet_ids         = [aws_subnet.central_private_a.id, aws_subnet.central_private_c.id]
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = aws_vpc.central.id

  tags = {
    Name = "${var.project_name}-tgw-attachment-central"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "spoke" {
  subnet_ids         = [aws_subnet.spoke_private.id]
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = aws_vpc.spoke.id

  tags = {
    Name = "${var.project_name}-tgw-attachment-spoke"
  }
}



# Central AZ-A routes to Spoke VPCs
resource "aws_route" "central_a_to_spoke" {
  route_table_id         = aws_route_table.central_private_a.id
  destination_cidr_block = var.spoke_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.central]
}



# Central AZ-C routes to Spoke VPCs
resource "aws_route" "central_c_to_spoke" {
  route_table_id         = aws_route_table.central_private_c.id
  destination_cidr_block = var.spoke_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.central]
}



resource "aws_route" "spoke_to_central" {
  route_table_id         = aws_route_table.spoke_private.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.main.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.spoke]
}


