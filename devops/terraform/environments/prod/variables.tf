# General Configuration
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "user-registration-microservice"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "DevOps Team"
}

variable "cost_center" {
  description = "Cost center for resource allocation"
  type        = string
  default     = "Engineering"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.2.0.0/16"  # Different CIDR for prod environment
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]  # 3 AZs for prod
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.2.10.0/24", "10.2.20.0/24", "10.2.30.0/24"]  # 3 AZs for prod
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true  # Enable for prod environment
}

variable "use_private_subnets" {
  description = "Whether to deploy instances in private subnets"
  type        = bool
  default     = true  # Use private subnets for prod security
}

# Security Configuration
variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["10.2.0.0/16"]  # Restrict SSH to VPC only in prod
}

# EC2 Configuration
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"  # Larger instances for prod
}

variable "instance_count" {
  description = "Number of EC2 instances"
  type        = number
  default     = 1  # Single instance for simpler prod setup
}

variable "enable_eip" {
  description = "Whether to create Elastic IPs for instances"
  type        = bool
  default     = false  # Not needed with ALB
}

variable "volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 30  # Larger volume for prod
}

# ALB Configuration
variable "enable_alb" {
  description = "Whether to create Application Load Balancer"
  type        = bool
  default     = true  # Always enabled for prod
}

variable "enable_deletion_protection" {
  description = "Whether to enable deletion protection on ALB (disable for dev/test)"
  type        = bool
  default     = false  # Changed default to false for easier management
}

# WAF Configuration  
variable "enable_waf" {
  description = "Enable WAF for ALB"
  type        = bool
  default     = true  # Enable WAF for prod security
}

# Key Pair Configuration
variable "key_pair_name" {
  description = "Name of the AWS key pair for EC2 access"
  type        = string
  default     = "user-registration-microservice-prod-key"
}

variable "create_key_pair" {
  description = "Whether to create a key pair"
  type        = bool
  default     = true
}

# Monitoring Configuration
variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring for instances"
  type        = bool
  default     = true
}

variable "enable_cloudwatch_alarms" {
  description = "Enable CloudWatch alarms"
  type        = bool
  default     = true
}

# Backup Configuration
variable "enable_backup" {
  description = "Enable automatic backups"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}


# Tags
variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "Production"
    Criticality = "High"
    Backup      = "Required"
  }
}
