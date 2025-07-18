#!/bin/bash

# Jenkins Credentials Automation Script
# This script automatically sets up Jenkins credentials using environment variables
# Usage: Export environment variables and run this script

set -e

echo "Setting up Jenkins credentials automatically..."

# Jenkins connection details
JENKINS_URL="${JENKINS_URL:-http://13.59.191.101:8080}"
JENKINS_USER="${JENKINS_USER:-admin}"
JENKINS_PASSWORD="${JENKINS_PASSWORD:-859ce99d4dcb4f9d8ca5834422e9903a}"

# Required environment variables
required_vars=(
    "DOCKER_HUB_USERNAME"
    "DOCKER_HUB_PASSWORD"
    "GITHUB_USERNAME" 
    "GITHUB_TOKEN"
    "AWS_SSH_PRIVATE_KEY_PATH"
)

# Check if required environment variables are set
check_required_vars() {
    echo "Checking required environment variables..."
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            echo "ERROR: Environment variable $var is not set"
            echo "Please set all required variables and try again"
            exit 1
        fi
    done
    echo "All required environment variables are set ✓"
}

# Function to create Jenkins credential
create_credential() {
    local cred_id=$1
    local cred_xml=$2
    
    echo "Creating credential: $cred_id"
    
    curl -X POST "$JENKINS_URL/credentials/store/system/domain/_/createCredentials" \
        --user "$JENKINS_USER:$JENKINS_PASSWORD" \
        --header "Content-Type: application/xml" \
        --data-binary "$cred_xml" \
        --silent --fail
    
    echo "Credential $cred_id created successfully ✓"
}

# Setup Docker Hub credentials
setup_docker_credentials() {
    echo "Setting up Docker Hub credentials..."
    
    local docker_xml="<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>docker-hub-credentials</id>
  <description>Docker Hub Registry Access</description>
  <username>$DOCKER_HUB_USERNAME</username>
  <password>$DOCKER_HUB_PASSWORD</password>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>"
    
    create_credential "docker-hub-credentials" "$docker_xml"
}

# Setup GitHub credentials
setup_github_credentials() {
    echo "Setting up GitHub credentials..."
    
    local github_xml="<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>github-credentials</id>
  <description>GitHub Repository Access</description>
  <username>$GITHUB_USERNAME</username>
  <password>$GITHUB_TOKEN</password>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>"
    
    create_credential "github-credentials" "$github_xml"
}

# Setup SSH credentials
setup_ssh_credentials() {
    echo "Setting up AWS SSH credentials..."
    
    # Read the private key content
    if [[ ! -f "$AWS_SSH_PRIVATE_KEY_PATH" ]]; then
        echo "ERROR: SSH private key file not found at $AWS_SSH_PRIVATE_KEY_PATH"
        exit 1
    fi
    
    local ssh_key_content=$(cat "$AWS_SSH_PRIVATE_KEY_PATH")
    
    local ssh_xml="<com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey>
  <scope>GLOBAL</scope>
  <id>aws-ssh-key</id>
  <description>AWS EC2 SSH Access</description>
  <username>ubuntu</username>
  <privateKeySource class=\"com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey\$DirectEntryPrivateKeySource\">
    <privateKey>$ssh_key_content</privateKey>
  </privateKeySource>
</com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey>"
    
    create_credential "aws-ssh-key" "$ssh_xml"
}

# Setup AWS credentials (if provided)
setup_aws_credentials() {
    if [[ -n "$AWS_ACCESS_KEY_ID" && -n "$AWS_SECRET_ACCESS_KEY" ]]; then
        echo "Setting up AWS credentials..."
        
        local aws_xml="<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>aws-credentials</id>
  <description>AWS Access Credentials</description>
  <username>$AWS_ACCESS_KEY_ID</username>
  <password>$AWS_SECRET_ACCESS_KEY</password>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>"
        
        create_credential "aws-credentials" "$aws_xml"
    else
        echo "AWS credentials not provided, skipping..."
    fi
}

# Main execution
main() {
    echo "=== Jenkins Credentials Automation ==="
    echo "Jenkins URL: $JENKINS_URL"
    echo
    
    check_required_vars
    echo
    
    setup_docker_credentials
    setup_github_credentials  
    setup_ssh_credentials
    setup_aws_credentials
    
    echo
    echo "=== All credentials set up successfully! ==="
    echo "You can now run your Jenkins pipelines with these credentials:"
    echo "- docker-hub-credentials: Docker registry access"
    echo "- github-credentials: GitHub repository access"
    echo "- aws-ssh-key: SSH access to AWS instances"
    
    if [[ -n "$AWS_ACCESS_KEY_ID" ]]; then
        echo "- aws-credentials: AWS API access"
    fi
}

# Help function
show_help() {
    cat << EOF
Jenkins Credentials Automation Script

USAGE:
    Export the required environment variables and run this script:
    
    export DOCKER_HUB_USERNAME="your-dockerhub-username"
    export DOCKER_HUB_PASSWORD="your-dockerhub-password"
    export GITHUB_USERNAME="your-github-username"
    export GITHUB_TOKEN="your-github-personal-access-token"
    export AWS_SSH_PRIVATE_KEY_PATH="/path/to/your/ssh-key.pem"
    
    # Optional AWS credentials
    export AWS_ACCESS_KEY_ID="your-aws-access-key"
    export AWS_SECRET_ACCESS_KEY="your-aws-secret-key"
    
    # Optional Jenkins connection override
    export JENKINS_URL="http://your-jenkins-url:8080"
    export JENKINS_USER="admin"
    export JENKINS_PASSWORD="your-jenkins-password"
    
    ./setup-jenkins-credentials.sh

EXAMPLE:
    # Create a .env file for convenience
    cat > jenkins-creds.env << EOF
    export DOCKER_HUB_USERNAME="destinyobs"
    export DOCKER_HUB_PASSWORD="your-dockerhub-password"
    export GITHUB_USERNAME="destinyobs"
    export GITHUB_TOKEN="ghp_your-github-token"
    export AWS_SSH_PRIVATE_KEY_PATH="/path/to/user-registration-dev-key.pem"
    EOF
    
    source jenkins-creds.env
    ./setup-jenkins-credentials.sh

EOF
}

# Check command line arguments
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
    exit 0
fi

# Run main function
main
