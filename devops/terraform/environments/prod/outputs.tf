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
  description = "Public IP addresses of instances (if using public subnets)"
  value       = var.use_private_subnets ? [] : module.ec2.instance_public_ips
}

output "instance_private_ips" {
  description = "Private IP addresses of instances"
  value       = module.ec2.instance_private_ips
}

output "instance_ids" {
  description = "Instance IDs"
  value       = module.ec2.instance_ids
}

# ALB Outputs
output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.alb.alb_dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  value       = module.alb.alb_zone_id
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = module.alb.target_group_arn
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

# SSH Connection (for private instances via bastion)
output "ssh_connection_info" {
  description = "SSH connection information"
  value = var.use_private_subnets ? {
    note = "Instances are in private subnets. SSH access requires bastion host or VPN."
    private_ips = module.ec2.instance_private_ips
  } : {
    commands = [
      for ip in module.ec2.instance_public_ips :
      "ssh -i ${var.project_name}-${var.environment}-key.pem ubuntu@${ip}"
    ]
  }
}

output "private_key_filename" {
  description = "Filename of the private key"
  value       = "${var.project_name}-${var.environment}-key.pem"
}

# Application Access
output "application_url" {
  description = "Primary URL to access the application"
  value       = "https://${module.alb.alb_dns_name}"
}

output "application_health_check_url" {
  description = "Health check URL"
  value       = "https://${module.alb.alb_dns_name}/health"
}

# Production Monitoring
output "cloudwatch_log_group" {
  description = "CloudWatch log group for application logs"
  value       = "/aws/ec2/${var.project_name}-${var.environment}"
}

# Environment Information
output "environment_info" {
  description = "Environment configuration summary"
  value = {
    environment         = var.environment
    instance_count      = var.instance_count
    instance_type       = var.instance_type
    use_private_subnets = var.use_private_subnets
    alb_enabled         = true
    nat_gateway_enabled = var.enable_nat_gateway
    deletion_protection = true  # Hardcoded to true for production
  }
}
