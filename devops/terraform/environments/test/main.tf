# Test Environment Configuration

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
    key    = "test/user-registration-microservice/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    use_lockfile   = true
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

  name_prefix         = "${var.project_name}-${var.environment}"
  instance_count      = var.instance_count
  instance_type       = var.instance_type
  key_name            = aws_key_pair.main.key_name
  security_group_ids  = [module.security.app_security_group_id]
  subnet_ids          = module.vpc.public_subnet_ids
  target_group_arn    = var.enable_alb ? module.alb[0].target_group_arn : null
  enable_eip          = var.enable_eip
  volume_size         = var.volume_size
}

# ALB Module (optional for test)
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

# Wait for instances to be ready
resource "time_sleep" "wait_for_instances" {
  depends_on      = [module.ec2]
  create_duration = "60s"
}

# Generate Ansible inventory dynamically
resource "local_file" "ansible_inventory" {
  content = templatefile("../../../ansible/inventory/template.ini", {
    environment  = var.environment
    instance_ips = module.ec2.instance_public_ips
  })
  filename = "../../../ansible/inventory/${var.environment}.ini"
  depends_on = [module.ec2]
}

# Generate Ansible variables file
resource "local_file" "ansible_vars" {
  content = templatefile("../../../ansible/group_vars/template.yml", {
    environment    = var.environment
    project_name   = var.project_name
    instance_type  = var.instance_type
    aws_region     = var.aws_region
    instance_count = var.instance_count
    instance_ips   = module.ec2.instance_public_ips
    enable_alb     = var.enable_alb
    alb_dns_name   = var.enable_alb ? module.alb[0].alb_dns_name : ""
  })
  filename = "../../../ansible/group_vars/${var.environment}.yml"
  depends_on = [module.ec2]
}

# Wait for instance to be ready and run Ansible
resource "null_resource" "run_ansible" {
  depends_on = [
    module.ec2,
    local_file.ansible_inventory,
    local_file.ansible_vars,
    local_file.private_key
  ]

  # SSH connection test
  connection {
    type        = "ssh"
    host        = module.ec2.instance_public_ips[0]
    user        = "ubuntu"
    private_key = var.create_key_pair ? tls_private_key.main.private_key_pem : file(var.key_pair_name)
    timeout     = "10m"
  }

  # Run Ansible playbook from local machine  
  provisioner "local-exec" {
    working_dir = "../../../ansible"
    command     = "cp ../terraform/environments/${var.environment}/${var.key_pair_name}.pem /tmp/${var.key_pair_name}.pem && chmod 600 /tmp/${var.key_pair_name}.pem && ANSIBLE_ROLES_PATH=./roles ansible-playbook -i inventory/${var.environment}.ini playbooks/site.yml --private-key=/tmp/${var.key_pair_name}.pem && rm -f /tmp/${var.key_pair_name}.pem"
    interpreter = ["bash", "-c"]
  }

  # Trigger re-run when instance changes
  triggers = {
    instance_ids = join(",", module.ec2.instance_ids)
  }
}
