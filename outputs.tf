output "alb_dns_name" {
  description = "DNS name of the internet-facing ALB"
  value       = aws_lb.internet_facing.dns_name
}

output "nlb_dns_name" {
  description = "DNS name of the internal NLB"
  value       = aws_lb.internal.dns_name
}

output "spoke_instance_ip" {
  description = "Private IP address of spoke VPC web instance"
  value       = aws_instance.spoke_web.private_ip
}

output "central_vpc_id" {
  description = "ID of the central VPC"
  value       = aws_vpc.central.id
}

output "spoke_vpc_id" {
  description = "ID of the spoke VPC"
  value       = aws_vpc.spoke.id
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

output "spoke_web_instance_id" {
  description = "Instance ID of spoke web server"
  value       = aws_instance.spoke_web.id
}