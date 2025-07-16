# Variables for Bastion Host Module

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where bastion host will be deployed"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for bastion host"
  type        = string
}

variable "ssh_allowed_cidrs" {
  description = "List of CIDR blocks allowed for SSH access"
  type        = list(string)
}

variable "key_name" {
  description = "Name of the EC2 Key Pair"
  type        = string
}

variable "bastion_instance_type" {
  description = "Instance type for bastion host"
  type        = string
  default     = "t3.micro"
}
