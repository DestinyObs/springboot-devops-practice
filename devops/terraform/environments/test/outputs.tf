# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

# EC2 Outputs
output "instance_public_ips" {
  description = "Public IP addresses of instances"
  value       = module.ec2.instance_public_ips
}

output "instance_private_ips" {
  description = "Private IP addresses of instances"
  value       = module.ec2.instance_private_ips
}

output "instance_ids" {
  description = "Instance IDs"
  value       = module.ec2.instance_ids
}

# SSH Connection
output "ssh_connection_commands" {
  description = "SSH connection commands"
  value = [
    for ip in module.ec2.instance_public_ips :
    "ssh -i ${var.project_name}-${var.environment}-key.pem ubuntu@${ip}"
  ]
}

output "private_key_filename" {
  description = "Filename of the private key"
  value       = "${var.project_name}-${var.environment}-key.pem"
}

# ALB Outputs (if enabled)
output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = var.enable_alb ? module.alb[0].load_balancer_dns_name : null
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  value       = var.enable_alb ? module.alb[0].load_balancer_zone_id : null
}

# Security Group Outputs
output "app_security_group_id" {
  description = "ID of the application security group"
  value       = module.security.app_security_group_id
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = module.security.alb_security_group_id
}

# Application Access
output "application_urls" {
  description = "URLs to access the application"
  value = var.enable_alb ? [
    "http://${module.alb[0].load_balancer_dns_name}:8080"
  ] : [
    for ip in module.ec2.instance_public_ips :
    "http://${ip}:8080"
  ]
}
