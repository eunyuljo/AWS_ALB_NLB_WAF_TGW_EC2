output "alb_dns_name" {
  description = "DNS name of the internet-facing ALB"
  value       = aws_lb.internet_facing.dns_name
}

output "nlb_dns_name" {
  description = "DNS name of the internal NLB"
  value       = aws_lb.internal.dns_name
}

output "spoke_lb_dns_names" {
  description = "DNS names of spoke VPC load balancers"
  value = {
    spoke_1 = aws_lb.spoke_1_internal.dns_name
    spoke_2 = aws_lb.spoke_2_internal.dns_name
    spoke_3 = aws_lb.spoke_3_internal.dns_name
  }
}

output "hub_vpc_id" {
  description = "ID of the hub VPC"
  value       = aws_vpc.hub.id
}

output "spoke_vpc_ids" {
  description = "IDs of the spoke VPCs"
  value = {
    spoke_1 = aws_vpc.spoke_1.id
    spoke_2 = aws_vpc.spoke_2.id
    spoke_3 = aws_vpc.spoke_3.id
  }
}

output "transit_gateway_id" {
  description = "ID of the Transit Gateway"
  value       = aws_ec2_transit_gateway.main.id
}

output "proxy_instance_ids" {
  description = "Instance IDs of proxy servers"
  value = {
    proxy_a = aws_instance.proxy_a.id
    proxy_c = aws_instance.proxy_c.id
  }
}

output "spoke_web_instance_ids" {
  description = "Instance IDs of spoke web servers"
  value = {
    spoke_1 = aws_instance.spoke_1_web.id
    spoke_2 = aws_instance.spoke_2_web.id
    spoke_3 = aws_instance.spoke_3_web.id
  }
}