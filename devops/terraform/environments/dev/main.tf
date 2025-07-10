# Development Environment Configuration

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket = "all-destinyobs-infra-terraform-states-xyz"
    key    = "dev/user-registration-microservice/terraform.tfstate"
    region = "us-east-2"
    dynamodb_table = "terraform-locks"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment   = var.environment
      Project       = var.project_name
      ManagedBy     = "Terraform"
      Owner         = var.owner
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
  enable_nat_gateway = var.enable_nat_gateway
}

# Security Module
module "security" {
  source = "../../modules/security"

  project_name         = var.project_name
  environment          = var.environment
  vpc_id               = module.vpc.vpc_id
  ssh_allowed_cidrs    = var.ssh_allowed_cidrs
}

# EC2 Module
module "ec2" {
  source = "../../modules/ec2"

  name_prefix        = "${var.project_name}-${var.environment}"
  instance_count     = var.instance_count
  instance_type      = var.instance_type
  key_name           = var.create_key_pair ? aws_key_pair.main[0].key_name : var.key_pair_name
  security_group_ids = [module.security.app_security_group_id]
  subnet_ids         = module.vpc.public_subnet_ids
  enable_eip         = false  # Set to false for dev
  target_group_arn   = var.enable_alb ? module.alb[0].target_group_arn : null

  common_tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# ALB Module
module "alb" {
  count  = var.enable_alb ? 1 : 0
  source = "../../modules/alb"

  name_prefix        = "${var.project_name}-${var.environment}"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.security.alb_security_group_id]
  
  target_port                     = 8080
  listener_port                   = 80
  health_check_path               = "/actuator/health"
  enable_deletion_protection      = false

  common_tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Generate TLS private key for SSH
resource "tls_private_key" "main" {
  count = var.create_key_pair ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096

  provisioner "local-exec" {
    command = "echo '${self.private_key_pem}' > ${var.key_pair_name}.pem && chmod 400 ${var.key_pair_name}.pem"
  }
}

# Key Pair for EC2 instances
resource "aws_key_pair" "main" {
  count = var.create_key_pair ? 1 : 0

  key_name   = var.key_pair_name
  public_key = tls_private_key.main[0].public_key_openssh

  tags = {
    Name        = var.key_pair_name
    Environment = var.environment
    Project     = var.project_name
  }
}
