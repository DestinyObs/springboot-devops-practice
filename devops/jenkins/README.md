# Jenkins CI/CD Pipeline

This directory contains Jenkins pipeline configurations and scripts for the Spring Boot user registration/authentication microservice CI/CD workflow.

## Overview

The Jenkins CI/CD pipeline implements a three-stage deployment workflow:

1. **Development**: Triggered by GitHub push, builds and deploys to dev environment
2. **Test**: Triggered by dev success, runs integration tests and deploys to test environment
3. **Production**: Triggered by test approval, implements blue-green deployment to production

## Directory Structure

```
devops/jenkins/
├── pipelines/
│   ├── Jenkinsfile.dev          # Development pipeline
│   ├── Jenkinsfile.test         # Test pipeline
│   └── Jenkinsfile.prod         # Production pipeline
└── scripts/
    ├── setup-jenkins.sh         # Jenkins initial configuration
    ├── create-jenkins-jobs.sh   # Jenkins job creation
    ├── deploy.sh                # Application deployment
    ├── health-check.sh          # Health verification
    ├── blue-green-deploy.sh     # Blue-green production deployment
    └── rollback.sh              # Rollback functionality
```

## Pipeline Stages

### Development Pipeline
- **Checkout**: Pull source code from GitHub
- **Build**: Compile Java code with Maven
- **Test**: Run unit tests with coverage reporting
- **Package**: Create JAR file
- **Docker Build**: Create Docker image
- **Push**: Push image to Docker Hub
- **Deploy**: Deploy to dev environment
- **Health Check**: Verify deployment health

### Test Pipeline
- **Checkout**: Pull source code
- **Pull Image**: Get latest dev image
- **Integration Tests**: Run integration test suite
- **Security Scan**: OWASP dependency check
- **Push**: Tag and push test image
- **Deploy**: Deploy to test environment
- **Health Check**: Verify test deployment
- **Approval**: Manual approval for production

### Production Pipeline
- **Checkout**: Pull source code
- **Pull Image**: Get approved test image
- **Readiness Check**: Production deployment validation
- **Push**: Tag and push production image
- **Blue-Green Deploy**: Zero-downtime deployment
- **Health Check**: Verify production deployment
- **Rollback Check**: Manual confirmation or auto-rollback

## Setup Instructions

### Prerequisites
- Jenkins server running (installed via Ansible)
- Docker Hub account for image storage
- GitHub repository with webhook access

### 1. Initial Jenkins Configuration
```bash
cd devops/jenkins/scripts
chmod +x setup-jenkins.sh
./setup-jenkins.sh
```

This script will:
- Install required Jenkins plugins
- Configure Maven and JDK tools
- Set up Docker Hub credentials
- Configure GitHub integration

### 2. Create Jenkins Jobs
```bash
chmod +x create-jenkins-jobs.sh
./create-jenkins-jobs.sh
```

This creates three pipeline jobs:
- `spring-boot-user-registration-dev`
- `spring-boot-user-registration-test`
- `spring-boot-user-registration-prod`

### 3. Configure GitHub Webhook
In your GitHub repository:
1. Go to Settings → Webhooks
2. Add webhook: `http://your-jenkins-server:8080/github-webhook/`
3. Select "Just the push event"
4. Ensure webhook is active

## Environment Configuration

### Development Environment
- **Port**: 8080
- **Database**: userdb_dev
- **Profile**: dev
- **Triggers**: GitHub push events

### Test Environment
- **Port**: 8081
- **Database**: userdb_test
- **Profile**: test
- **Triggers**: Dev pipeline success

### Production Environment
- **Port**: 8082
- **Database**: userdb_prod
- **Profile**: prod
- **Triggers**: Test pipeline approval

## Deployment Scripts

### Standard Deployment (`deploy.sh`)
- Pulls Docker image from registry
- Creates environment-specific docker-compose configuration
- Deploys MySQL and application containers
- Performs health checks

### Blue-Green Deployment (`blue-green-deploy.sh`)
- Creates parallel green environment
- Switches traffic using nginx proxy
- Validates new deployment
- Removes old blue environment

### Health Check (`health-check.sh`)
- Verifies container status
- Tests application endpoints
- Checks database connectivity
- Validates API functionality

### Rollback (`rollback.sh`)
- Identifies previous image version
- Deploys previous version
- Updates load balancer configuration
- Validates rollback success

## Credentials Management

Required Jenkins credentials:
- **docker-hub-credentials**: Docker Hub username/password
- **github-credentials**: GitHub username/token (optional)

## Monitoring and Logging

Pipeline provides:
- **Test Results**: Unit and integration test reports
- **Code Coverage**: JaCoCo coverage reports
- **Build Artifacts**: JAR files and deployment summaries
- **Health Reports**: Deployment verification logs

## Troubleshooting

### Common Issues

**Pipeline Fails at Docker Build**
- Verify Docker daemon is running
- Check Docker Hub credentials
- Ensure Dockerfile is present

**Deployment Fails**
- Check target server connectivity
- Verify SSH key permissions
- Check available disk space

**Health Check Fails**
- Verify application ports
- Check database connection
- Review application logs

### Debug Commands
```bash
# Check Jenkins logs
docker logs jenkins

# Check deployment logs
ssh -i key.pem ubuntu@server "docker-compose logs"

# Manual health check
curl -f http://server:port/actuator/health
```

## Security Considerations

- SSH keys automatically generated by Terraform
- Credentials stored in Jenkins credential store
- Container images scanned for vulnerabilities
- Database credentials managed via environment variables
- Network access controlled by security groups

## Maintenance

### Regular Tasks
- Monitor pipeline success rates
- Update Docker base images
- Review security scan results
- Clean up old Docker images
- Backup Jenkins configuration

### Scaling
- Pipeline supports multiple environments
- Can be extended for additional deployment targets
- Supports parallel execution for faster builds
- Compatible with Jenkins cluster setup
