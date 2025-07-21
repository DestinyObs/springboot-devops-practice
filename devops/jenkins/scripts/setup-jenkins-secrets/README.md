# Jenkins Credentials Setup

This directory contains scripts to automatically set up Jenkins credentials via the REST API.

## Files

- `setup-credentials.sh` - Main script to create Jenkins credentials
- `secrets.env.example` - Example environment file showing required variables
- `secrets.env` - Your actual credentials (excluded from git)

## Setup Instructions

1. **Copy the example file:**
   ```bash
   cp secrets.env.example secrets.env
   ```

2. **Edit `secrets.env` with your actual credentials:**
   - `JENKINS_URL` - Your Jenkins server URL
   - `JENKINS_USER` - Jenkins admin username  
   - `JENKINS_PASSWORD` - Jenkins admin password
   - `DOCKER_USERNAME` - Your Docker Hub username
   - `DOCKER_PASSWORD` - Your Docker Hub password
   - `GITHUB_USERNAME` - Your GitHub username
   - `GITHUB_TOKEN` - Your GitHub Personal Access Token
   - `SSH_KEY_PATH` - Path to your SSH private key file

3. **Run the setup script:**
   ```bash
   ./setup-credentials.sh
   ```

## Created Credentials

The script creates three global credentials in Jenkins:

1. **docker-hub-credentials** - Docker Hub username/password for registry access
2. **github-credentials** - GitHub username/token for repository access  
3. **aws-ssh-key** - SSH private key for AWS EC2 access

## Security Notes

- The `secrets.env` file is excluded from git via `.gitignore`
- Never commit actual credentials to version control
- Use the `.example` file to show the required format
- The script uses Jenkins CSRF protection and cookie-based authentication for security

## Usage in Jenkins Pipelines

Reference these credentials in your Jenkinsfiles:

```groovy
environment {
    DOCKER_HUB_CREDENTIALS = credentials('docker-hub-credentials')
    GITHUB_CREDENTIALS = credentials('github-credentials')
}

// For SSH access
sshagent(['aws-ssh-key']) {
    // SSH commands here
}
```
