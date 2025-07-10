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
  description = "Public IP addresses of the instances"
  value       = module.ec2.instance_public_ips
}

output "instance_private_ips" {
  description = "Private IP addresses of the instances"
  value       = module.ec2.instance_private_ips
}

output "instance_ids" {
  description = "EC2 instance IDs"
  value       = module.ec2.instance_ids
}

# SSH Connection
output "ssh_connection_commands" {
  description = "Commands to SSH into the instances"
  value       = [for ip in module.ec2.instance_public_ips : "ssh -i ${var.key_pair_name}.pem ubuntu@${ip}"]
}

output "private_key_filename" {
  description = "Filename of the generated private key"
  value       = var.create_key_pair ? "${var.key_pair_name}.pem" : "Key pair not created by Terraform"
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
