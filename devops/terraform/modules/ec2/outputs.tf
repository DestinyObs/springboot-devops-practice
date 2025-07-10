# EC2 Module Outputs

output "instance_ids" {
  description = "List of EC2 instance IDs"
  value       = aws_instance.app_server[*].id
}

output "instance_public_ips" {
  description = "List of public IP addresses of the instances"
  value       = aws_instance.app_server[*].public_ip
}

output "instance_private_ips" {
  description = "List of private IP addresses of the instances"
  value       = aws_instance.app_server[*].private_ip
}

output "elastic_ips" {
  description = "List of Elastic IP addresses (if enabled)"
  value       = var.enable_eip ? aws_eip.app_eip[*].public_ip : []
}

output "instance_dns_names" {
  description = "List of public DNS names of the instances"
  value       = aws_instance.app_server[*].public_dns
}
