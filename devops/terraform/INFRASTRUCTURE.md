# Multi-Environment Infrastructure Setup

This document describes the complete infrastructure setup for the User Registration Microservice across Dev, Test, and Production environments.

## Environment Architecture

### Development Environment
- **Purpose**: Development and initial testing
- **Instance Count**: 1 x t3.micro
- **Network**: Public subnets only
- **Load Balancer**: Disabled (cost optimization)
- **NAT Gateway**: Disabled (cost optimization)
- **SSH Access**: Open (0.0.0.0/0)

### Test Environment
- **Purpose**: Integration testing and staging
- **Instance Count**: 2 x t3.small
- **Network**: Public subnets with ALB
- **Load Balancer**: Enabled
- **NAT Gateway**: Enabled
- **SSH Access**: Open (0.0.0.0/0)

### Production Environment
- **Purpose**: Production workloads
- **Instance Count**: 3 x t3.medium
- **Network**: Private subnets with NAT Gateway
- **Load Balancer**: Enabled with deletion protection
- **NAT Gateway**: Enabled
- **SSH Access**: Restricted to VPC CIDR

## Infrastructure Components

### VPC Configuration
- **Dev**: 10.0.0.0/16
- **Test**: 10.1.0.0/16
- **Prod**: 10.2.0.0/16

### Security Groups
- **ALB Security Group**: HTTP/HTTPS from internet
- **App Security Group**: Port 8989 from ALB, SSH from allowed CIDRs, Jenkins on port 8080

### Auto Scaling (Future Enhancement)
Currently using fixed instance counts, ready for Auto Scaling Group integration.

## Deployment Instructions

### Prerequisites
1. AWS CLI configured with appropriate credentials
2. Terraform >= 1.0 installed
3. Ansible installed

### Deploy Development Environment
```bash
cd devops/terraform/environments/dev
terraform init
terraform plan
terraform apply
```

### Deploy Test Environment
```bash
cd devops/terraform/environments/test
terraform init
terraform plan
terraform apply
```

### Deploy Production Environment
```bash
cd devops/terraform/environments/prod
terraform init
terraform plan
terraform apply
```

## Key Features

### Security
- Environment-specific SSH access controls
- Private subnets for production workloads
- Security groups with least-privilege access
- Encrypted state storage with DynamoDB locking

### High Availability
- Multi-AZ deployment for production
- Application Load Balancer with health checks
- Auto-generated SSH keys with proper permissions

### Automation
- Terraform automatically triggers Ansible configuration
- Dynamic inventory generation
- Environment-specific configurations

### Cost Optimization
- Smaller instances for dev/test
- Optional components (ALB, NAT Gateway) for cost control
- Resource tagging for cost tracking

## Monitoring and Maintenance

### Health Checks
- ALB health checks on port 8989
- Application health endpoint: `/health`

### Logging
- CloudWatch logs for application
- VPC Flow Logs for network monitoring

### Backup Strategy
- EBS volume snapshots
- Configuration stored in Git

## Environment Outputs

Each environment provides:
- Instance IP addresses
- SSH connection commands
- Application URLs
- Load balancer DNS names
- Security group IDs

## Next Steps

1. **CI/CD Integration**: Jenkins pipelines for automated deployments
2. **Monitoring**: Prometheus/Grafana setup
3. **Auto Scaling**: Implement Auto Scaling Groups with CloudWatch metrics
4. **Blue-Green Deployment**: Zero-downtime deployment strategy
5. **Database**: RDS Multi-AZ for production persistence

## Troubleshooting

### Common Issues
- **SSH Connection**: Check security group rules and key permissions
- **Application Access**: Verify security group port 8989 access
- **Ansible Failures**: Check inventory file generation and key paths

### Debug Commands
```bash
# Check instance status
aws ec2 describe-instances --filters "Name=tag:Environment,Values=dev"

# Test SSH connectivity
ssh -i user-registration-microservice-dev-key.pem ubuntu@<instance-ip>

# Check application health
curl http://<instance-ip>:8989/health

# Check Jenkins access  
curl http://<instance-ip>:8080
```

## Security Considerations

### Production Environment
- Instances deployed in private subnets
- SSH access restricted to VPC CIDR
- ALB with deletion protection enabled
- Detailed monitoring enabled

### Access Control
- IAM roles with least-privilege permissions
- Encrypted communication between components
- Regular security group audits

This infrastructure provides a solid foundation for the Spring Boot microservice with proper environment separation, security controls, and scalability considerations.
