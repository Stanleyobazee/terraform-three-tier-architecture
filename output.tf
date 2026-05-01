output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.Three_Tier_VPC.id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.Three_Tier_ALB.dns_name
}

output "bastion_public_ip" {
  description = "Public IP of the Bastion Host"
  value       = aws_instance.Three_Tier_Bastion_Instance.public_ip
}

output "nat_gateway_ip" {
  description = "Elastic IP of the NAT Gateway"
  value       = aws_eip.Three_Tier_NAT_EIP_A.public_ip
}
