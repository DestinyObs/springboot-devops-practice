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
output "instance_private_ips" {
  description = "Private IP addresses of the instances"
  value       = module.ec2.instance_private_ips
}

output "instance_ids" {
  description = "EC2 instance IDs"
  value       = module.ec2.instance_ids
}

# SSH Connection (through bastion or VPN)
output "ssh_connection_info" {
  description = "SSH connection information for private instances"
  value       = "Instances are in private subnets. Use bastion host or VPN to connect."
}

output "private_key_filename" {
  description = "Filename of the generated private key"
  value       = var.create_key_pair ? "${var.key_pair_name}.pem" : "Key pair not created by Terraform"
}

# ALB Outputs
output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.alb.load_balancer_dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  value       = module.alb.load_balancer_zone_id
}

output "application_url" {
  description = "URL to access the application"
  value       = "http://${module.alb.load_balancer_dns_name}"
}

output "health_check_url" {
  description = "Health check endpoint URL"
  value       = "http://${module.alb.load_balancer_dns_name}/actuator/health"
}
