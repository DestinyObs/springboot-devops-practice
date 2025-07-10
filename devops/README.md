# DevOps Infrastructure & Automation

This directory contains all DevOps-related infrastructure and automation for the **User Registration Microservice** project. Following industry best practices with clear separation of concerns.

## 🎯 Project Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Terraform     │───▶│     Ansible     │───▶│    CI/CD        │
│  (Infrastructure)│    │  (Configuration)│    │   (Jenkins)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                       │                       │
        ▼                       ▼                       ▼
   AWS Resources          Server Setup           App Deployment
   • EC2 Instances        • Java/Maven           • Docker Build
   • VPC/Networking       • Docker Engine        • Container Deploy
   • Security Groups      • Docker Compose       • Health Checks
   • Key Pairs           • MySQL Container       • Monitoring
```

## 📁 Directory Structure

```
devops/
├── terraform/              # Infrastructure as Code
│   ├── environments/       # Environment-specific configs
│   │   ├── dev/            # Development (1x t3.micro, Ubuntu)
│   │   ├── test/           # Testing (2x t3.small, Ubuntu + ALB)
│   │   └── prod/           # Production (3x t3.medium, Ubuntu + ALB)
│   ├── modules/            # Reusable Terraform modules
│   │   ├── vpc/            # Networking infrastructure
│   │   ├── security/       # Security groups
│   │   ├── ec2/            # EC2 instances (Ubuntu AMI)
│   │   └── alb/            # Application Load Balancer
│   └── scripts/            # Helper automation scripts
├── ansible/                # Configuration Management (Future)
│   ├── playbooks/          # Server configuration playbooks
│   ├── roles/              # Reusable roles
│   └── inventory/          # Dynamic inventory
└── ci-cd/                  # CI/CD Pipeline (Future)
    ├── jenkins/            # Jenkins pipeline definitions
    └── docker/             # Docker configurations
```

## 🔧 Tool Responsibilities

### **Terraform (Infrastructure Only)**
- ✅ AWS EC2 instances (Ubuntu 22.04 LTS)
- ✅ VPC, subnets, routing, NAT gateways
- ✅ Security groups for ALB and EC2
- ✅ SSH key pairs (auto-generated)
- ✅ Application Load Balancer (test/prod)

### **Ansible (Configuration - Future Phase)**
- 🔄 Java and Maven installation
- 🔄 Docker and Docker Compose setup
- 🔄 Application deployment
- 🔄 MySQL container configuration
- 🔄 System hardening and monitoring

### **CI/CD (Pipeline - Future Phase)**
- 🔄 Jenkins pipeline setup
- 🔄 GitHub webhook integration
- 🔄 Docker image building
- 🔄 Automated testing
- 🔄 Multi-environment deployment

## 🚀 Getting Started

### Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform >= 1.0 installed
- Git for version control

### 1. Development Environment
```bash
# Navigate to dev environment
cd devops/terraform/environments/dev

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Deploy infrastructure
terraform apply
```

### 2. Access Your Infrastructure
After deployment, Terraform outputs:
- EC2 instance public IPs
- SSH connection commands
- Private key filename (auto-generated)
- Application URLs (if ALB enabled)

### 3. Connect to Your Instances
```bash
# SSH to instances (key automatically created)
ssh -i user-registration-dev-key.pem ubuntu@<instance-ip>
```

## 🌍 Environment Specifications

| Environment | Instance Type | Count | ALB | NAT Gateway | Purpose |
|-------------|---------------|-------|-----|-------------|---------|
| **dev**     | t3.micro      | 1     | ❌  | ❌          | Development & testing |
| **test**    | t3.small      | 2     | ✅  | ✅          | Integration testing |
| **prod**    | t3.medium     | 3     | ✅  | ✅          | Production workloads |

## 📱 Application Stack

- **Backend**: Spring Boot (Java)
- **Database**: MySQL (Docker container)
- **Container Runtime**: Docker + Docker Compose
- **Operating System**: Ubuntu 22.04 LTS
- **Load Balancer**: AWS ALB (test/prod)

## 🔐 Security Features

- **Network Isolation**: VPC with public/private subnets
- **Access Control**: Security groups with least privilege
- **Encryption**: EBS volumes encrypted at rest
- **SSH Access**: Key-based authentication only
- **Production**: Private subnets for EC2 instances

## 📋 Next Steps

1. **✅ Phase 1**: Infrastructure provisioning (Terraform) - **COMPLETED**
2. **🔄 Phase 2**: Server configuration (Ansible) - **PENDING**
3. **🔄 Phase 3**: CI/CD pipeline setup (Jenkins) - **PENDING**
4. **🔄 Phase 4**: Monitoring & alerting (Prometheus/Grafana) - **PENDING**

## 🤝 Project Alignment

This infrastructure strictly follows the project outline:
- **Terraform**: Infrastructure provisioning only
- **Ubuntu AMI**: As specified (not Amazon Linux)
- **MySQL in containers**: Not using RDS
- **Separation of concerns**: Clear boundaries between tools
- **Automated deployment**: Zero manual AWS console work

---

Ready to deploy your infrastructure? Start with the development environment and work your way up! 🚀
