# Terraform Infrastructure as Code (IaC)

This directory contains Terraform Infrastructure as Code for provisioning AWS infrastructure for the User Registration Microservice. Following DevOps best practices, **Terraform handles only infrastructure provisioning** while **Ansible handles all configuration and software installation**.

## � Terraform Scope (Infrastructure Only)

**What Terraform Manages:**
- ✅ AWS EC2 instances (Ubuntu 22.04 LTS)
- ✅ VPC, subnets, routing, and networking
- ✅ Security groups and network ACLs
- ✅ Key pairs for SSH access
- ✅ Application Load Balancer (optional)

**What Terraform Does NOT Handle:**
- ❌ Java/Maven installation (Ansible's job)
- ❌ Docker installation and configuration (Ansible's job)
- ❌ MySQL setup (runs in Docker containers)
- ❌ Jenkins setup (Ansible's job)
- ❌ Application deployment (CI/CD pipeline)

## 📱 Application Architecture

- **Spring Boot Application**: Runs in Docker containers on EC2
- **MySQL Database**: Runs in Docker containers (not RDS)
- **Container Orchestration**: Docker Compose on EC2 instances
- **Configuration Management**: Handled by Ansible post-infrastructure

## 📁 Structure

```
terraform/
├── environments/          # Environment-specific configurations
│   ├── dev/              # Development (t3.micro, Ubuntu AMI)
│   ├── test/             # Testing (t3.small, Ubuntu AMI)
│   └── prod/             # Production (t3.medium+, Ubuntu AMI)
├── modules/              # Reusable Terraform modules
│   ├── vpc/              # VPC, subnets, NAT gateways, routing
│   ├── security/         # Security groups for ALB and EC2
│   ├── ec2/              # EC2 instances with Ubuntu AMI
│   └── alb/              # Application Load Balancer (optional)
├── shared/               # Shared resources (S3 state, DynamoDB locks)
├── scripts/              # Automation scripts (Windows & Linux)
│   ├── terraform.ps1     # PowerShell helper for Windows
│   ├── terraform.sh      # Bash helper for Linux/Mac
│   └── manage-keys.sh    # SSH key pair management
└── USAGE_GUIDE.md        # Detailed documentation
```

## Fully Automated Deployment

**Zero Manual Setup Required!** 

Terraform automatically creates:
- ✅ SSH Key Pairs (saves private key as .pem file)
- ✅ Ubuntu 22.04 LTS EC2 instances
- ✅ VPC with public/private subnets
- ✅ Security groups with proper rules
- ✅ Application Load Balancer (test/prod)

**No AWS Console work needed!**

### Step 2: Setup Shared Resources (S3 Bucket for State)
```bash
cd terraform
./scripts/terraform.sh setup
```

### Step 3: Deploy Development Environment
```bash
# Create SSH key pair for EC2 access
./scripts/manage-keys.sh create dev

# Initialize and deploy dev environment
./scripts/terraform.sh init dev
./scripts/terraform.sh plan dev
./scripts/terraform.sh apply dev

# Get application URL
./scripts/terraform.sh output dev
```

## 🌍 Environment Configuration

| Environment | Instance Type | RDS Class | Features |
|------------|---------------|-----------|----------|
| **dev** | t3.micro | db.t3.micro | Single AZ, no NAT, simplified security |
| **test** | t3.small | db.t3.small | Multi-AZ, monitoring, backups |
| **prod** | t3.medium+ | db.r5.large | HA, WAF, SSL, encryption, monitoring |

## 🔐 Security Features

- **Network**: Private subnets, security groups, NACLs
- **Application**: WAF, SSL/TLS, encrypted storage
- **Access**: SSH keys, IAM roles, principle of least privilege
- **Monitoring**: CloudWatch logs, Performance Insights, alarms

## Prerequisites

1. **Terraform** >= 1.0.0
2. **AWS CLI** configured with credentials
3. **Bash** (Linux/Mac) - Since you're on Ubuntu
4. **jq** (for JSON parsing in scripts)

## Available Commands

```bash
# Infrastructure management
./terraform.sh setup                    # Create shared resources
./terraform.sh init <env>              # Initialize environment
./terraform.sh plan <env>              # Plan changes
./terraform.sh apply <env>             # Apply changes
./terraform.sh destroy <env>           # Destroy environment
./terraform.sh output <env>            # Show outputs
./terraform.sh validate                # Validate all configs

# Key management
./scripts/manage-keys.sh create <env>   # Create SSH key pair
./scripts/manage-keys.sh list           # List key pairs
./scripts/manage-keys.sh delete <env>   # Delete key pair
```

## 📋 Next Steps

1. **Commit the terraform code** to your repository
2. **Push to GitHub** so you can pull it on your Ubuntu server
3. **Deploy development environment** step by step
4. **Test the infrastructure** before moving to test/prod
5. **Set up CI/CD pipelines** once dev is working

This infrastructure provides a production-ready foundation for your microservice following enterprise DevOps standards!
