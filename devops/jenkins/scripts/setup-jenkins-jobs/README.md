# Jenkins CI/CD Pipeline Setup

This directory contains scripts to automatically create Jenkins pipeline jobs for the complete CI/CD workflow.

## Files

- `setup-jobs.sh` - Main script to create Jenkins pipeline jobs
- `jobs.env.example` - Example environment file showing required configuration

## Pipeline Architecture

```
GitHub Push → Dev Pipeline → Test Pipeline → Production Pipeline
     ↓              ↓              ↓              ↓
   Trigger      Auto Build    Auto Deploy   Manual Approval
```

### Job Flow:
1. **user-registration-dev** - Triggered by GitHub push to main branch
2. **user-registration-test** - Triggered by successful dev build 
3. **user-registration-prod** - Manual approval required

## Setup Instructions

1. **Copy the example file:**
   ```bash
   cp jobs.env.example jobs.env
   ```

2. **Edit `jobs.env` with your actual configuration:**
   - `JENKINS_URL` - Your Jenkins server URL
   - `JENKINS_USER` - Jenkins admin username  
   - `JENKINS_PASSWORD` - Jenkins admin password
   - `GITHUB_REPO_URL` - Your GitHub repository URL
   - `DEV_INSTANCE_IP` - Development server IP
   - `TEST_INSTANCE_IP` - Test server IP
   - `PROD_INSTANCE_IPS` - Production server IPs (comma-separated)

3. **Run the setup script:**
   ```bash
   ./setup-jobs.sh
   ```

## Created Pipeline Jobs

### 1. Development Pipeline (`user-registration-dev`)
- **Trigger**: GitHub push to main branch
- **Actions**: 
  - Maven build and test
  - Docker image creation
  - Deploy to dev instance
  - Health check verification
  - Trigger test pipeline on success

### 2. Test Pipeline (`user-registration-test`)
- **Trigger**: Successful dev pipeline completion
- **Actions**:
  - Pull dev image
  - Deploy to test environment
  - Integration tests
  - Tag image for production
  - Trigger prod pipeline

### 3. Production Pipeline (`user-registration-prod`)
- **Trigger**: Manual approval required
- **Actions**:
  - Deploy to all production instances
  - Load balancer health checks
  - Production verification
  - Final release tagging

## Pipeline Configuration

Each job references Jenkinsfile from the repository:
- `devops/jenkins/pipelines/Jenkinsfile.dev`
- `devops/jenkins/pipelines/Jenkinsfile.test`  
- `devops/jenkins/pipelines/Jenkinsfile.prod`

## Required Jenkins Credentials

Ensure these credentials are created (use setup-credentials.sh):
- `docker-hub-credentials` - Docker registry access
- `github-credentials` - GitHub repository access
- `aws-ssh-key` - EC2 instance SSH access

## Environment Variables Used

All jobs use these environment variables from jobs.env:
- `DOCKER_REGISTRY` - Docker Hub username
- `DOCKER_IMAGE_NAME` - Docker image name
- `AWS_REGION` - AWS region for deployments
- `APP_PORT` - Application port (8989)
- `HEALTH_CHECK_ENDPOINT` - Health check URL path

## Monitoring Pipeline

After setup, monitor your pipeline:
1. Check job status in Jenkins dashboard
2. View build logs for debugging
3. Monitor application health endpoints
4. Check Docker Hub for published images

## Troubleshooting

Common issues and solutions:
- **Job creation fails**: Check Jenkins credentials and permissions
- **GitHub trigger not working**: Verify webhook configuration
- **Build fails**: Check Jenkinsfile syntax and credentials
- **Deployment fails**: Verify SSH keys and instance access
