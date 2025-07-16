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
  value       = module.alb.load_balancer_dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  value       = module.alb.load_balancer_zone_id
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

# SSM Connection (for secure access to instances)
output "ssm_connection_info" {
  description = "SSM connection information for secure access"
  value = {
    note = "Use AWS Systems Manager Session Manager for secure access to instances"
    instance_ids = module.ec2.instance_ids
    ssm_commands = [
      for id in module.ec2.instance_ids :
      "aws ssm start-session --target ${id}"
    ]
    deployment_guide = "See deployment-instructions-${var.environment}.md for manual deployment steps"
  }
}

output "private_key_filename" {
  description = "Filename of the private key"
  value       = "${var.project_name}-${var.environment}-key.pem"
}

# Application Access
output "application_url" {
  description = "Primary URL to access the application"
  value       = "https://${module.alb.load_balancer_dns_name}"
}

output "application_health_check_url" {
  description = "Health check URL"
  value       = "https://${module.alb.load_balancer_dns_name}/health"
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

# SSM IAM Resources
output "ssm_role_arn" {
  description = "ARN of the SSM IAM role"
  value       = aws_iam_role.ssm_role.arn
}

output "ssm_instance_profile_name" {
  description = "Name of the SSM instance profile"
  value       = aws_iam_instance_profile.ssm_profile.name
}

# Manual deployment command
output "deployment_command" {
  description = "Command to run Ansible on the instances"
  value = "cd /home/ubuntu/ansible && ansible-playbook -i inventory/${var.environment}.ini playbooks/site.yml --connection=local"
}
