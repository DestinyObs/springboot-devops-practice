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
  default     = "test"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "DevOps Team"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.1.0.0/16"  # Different CIDR for test environment
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.1.10.0/24", "10.1.20.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true  # Enable for test environment
}

# Security Configuration
variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# EC2 Configuration
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"  # Slightly larger for test
}

variable "instance_count" {
  description = "Number of EC2 instances"
  type        = number
  default     = 2  # Multiple instances for test
}

variable "enable_eip" {
  description = "Whether to create Elastic IPs for instances"
  type        = bool
  default     = false
}

variable "volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 20
}

# ALB Configuration
variable "enable_alb" {
  description = "Whether to create Application Load Balancer"
  type        = bool
  default     = true  # Enable ALB for test environment
}

# WAF Configuration  
variable "enable_waf" {
  description = "Enable WAF for ALB"
  type        = bool
  default     = false  # Disabled for test environment
}

# Key Pair Configuration
variable "key_pair_name" {
  description = "Name of the AWS key pair for EC2 access"
  type        = string
  default     = "user-registration-microservice-test-key"
}

variable "create_key_pair" {
  description = "Whether to create a key pair"
  type        = bool
  default     = true
}

# Tags
variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
