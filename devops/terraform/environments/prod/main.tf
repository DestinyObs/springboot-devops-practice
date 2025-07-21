# Production Environment Configuration

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
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }

  backend "s3" {
    bucket = "all-destinyobs-infra-terraform-states-xyz"
    key    = "prod/user-registration-microservice/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    use_lockfile   = false
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
      CostCenter    = var.cost_center
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
  availability_zones = data.aws_availability_zones.available.names
  enable_nat_gateway = var.enable_nat_gateway
}

# Security Module
module "security" {
  source = "../../modules/security"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  ssh_allowed_cidrs = var.ssh_allowed_cidrs
}

# EC2 Module
module "ec2" {
  source = "../../modules/ec2"

  name_prefix          = "user-reg-${var.environment}"
  instance_count       = var.instance_count
  instance_type        = var.instance_type
  key_name             = aws_key_pair.main.key_name
  security_group_ids   = [module.security.app_security_group_id]
  subnet_ids           = module.vpc.public_subnet_ids  # Use public subnets for internet access
  enable_eip           = false
  volume_size          = var.volume_size
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name

  # Add SSM role for server management
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    SSMManaged  = "true"
  }
}

# ALB Module (mandatory for prod)
module "alb" {
  source = "../../modules/alb"

  name_prefix        = "user-reg-${var.environment}"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.security.alb_security_group_id]
  
  target_port                     = 8989
  listener_port                   = 80
  health_check_path               = "/actuator/health"
  enable_deletion_protection      = var.enable_deletion_protection

  common_tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Target group attachment for ALB (handled separately to avoid count issues)
resource "aws_lb_target_group_attachment" "prod_attachment" {
  count            = var.instance_count
  target_group_arn = module.alb.target_group_arn
  target_id        = module.ec2.instance_ids[count.index]
  port             = 8989
  depends_on       = [module.ec2, module.alb]
}

# Generate TLS private key for SSH
resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair
resource "aws_key_pair" "main" {
  key_name   = var.key_pair_name
  public_key = tls_private_key.main.public_key_openssh
}

# Save private key to file with proper permissions
resource "local_file" "private_key" {
  content         = tls_private_key.main.private_key_pem
  filename        = "${var.key_pair_name}.pem"
  file_permission = "0600"
}

# IAM Role for SSM
resource "aws_iam_role" "ssm_role" {
  name = "${var.project_name}-${var.environment}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-ssm-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Attach SSM managed policy
resource "aws_iam_role_policy_attachment" "ssm_managed_instance" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile for SSM
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${var.project_name}-${var.environment}-ssm-profile"
  role = aws_iam_role.ssm_role.name

  tags = {
    Name        = "${var.project_name}-${var.environment}-ssm-profile"
    Environment = var.environment
    Project     = var.project_name
  }
}




