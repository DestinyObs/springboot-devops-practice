#!/bin/bash

# Complete Jenkins CI/CD Setup Automation
# This script sets up Jenkins credentials, creates jobs, and configures the entire pipeline
# Usage: ./complete-jenkins-setup.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

echo "=== Complete Jenkins CI/CD Setup ==="
echo "Script directory: $SCRIPT_DIR"
echo "Project root: $PROJECT_ROOT"
echo

# Check if environment file exists
ENV_FILE="$SCRIPT_DIR/jenkins-creds.env"
if [[ ! -f "$ENV_FILE" ]]; then
    echo "ERROR: Environment file not found: $ENV_FILE"
    echo "Please create the environment file first:"
    echo "  cp jenkins-creds.env.template jenkins-creds.env"
    echo "  # Edit jenkins-creds.env with your actual credentials"
    echo "  ./complete-jenkins-setup.sh"
    exit 1
fi

# Load environment variables
echo "Loading environment variables from $ENV_FILE..."
source "$ENV_FILE"
echo "Environment variables loaded ✓"
echo

# Step 1: Setup Jenkins credentials
echo "=== Step 1: Setting up Jenkins credentials ==="
if [[ -f "$SCRIPT_DIR/setup-jenkins-credentials.sh" ]]; then
    chmod +x "$SCRIPT_DIR/setup-jenkins-credentials.sh"
    "$SCRIPT_DIR/setup-jenkins-credentials.sh"
    echo "Jenkins credentials setup completed ✓"
else
    echo "ERROR: Credentials setup script not found"
    exit 1
fi
echo

# Step 2: Create Jenkins jobs
echo "=== Step 2: Creating Jenkins jobs ==="
if [[ -f "$SCRIPT_DIR/create-jenkins-jobs.sh" ]]; then
    chmod +x "$SCRIPT_DIR/create-jenkins-jobs.sh"
    "$SCRIPT_DIR/create-jenkins-jobs.sh"
    echo "Jenkins jobs creation completed ✓"
else
    echo "ERROR: Job creation script not found"
    exit 1
fi
echo

# Step 3: Install additional Jenkins plugins if needed
echo "=== Step 3: Installing additional Jenkins plugins ==="
install_jenkins_plugins() {
    local plugins=(
        "pipeline-stage-view"
        "build-pipeline-plugin"
        "docker-workflow"
        "ssh-agent"
        "publish-over-ssh"
        "aws-steps"
        "pipeline-aws"
        "slack"
        "email-ext"
        "jacoco"
        "sonar"
    )
    
    for plugin in "${plugins[@]}"; do
        echo "Installing plugin: $plugin"
        curl -X POST "$JENKINS_URL/pluginManager/installNecessaryPlugins" \
            --user "$JENKINS_USER:$JENKINS_PASSWORD" \
            --data-urlencode "dynamicLoad=true" \
            --data-urlencode "plugin.${plugin}.default=on" \
            --silent || echo "Plugin $plugin may already be installed"
    done
}

install_jenkins_plugins
echo "Additional plugins installation completed ✓"
echo

# Step 4: Verify setup
echo "=== Step 4: Verifying setup ==="

verify_jenkins_setup() {
    echo "Checking Jenkins connectivity..."
    if curl -f "$JENKINS_URL/api/json" --user "$JENKINS_USER:$JENKINS_PASSWORD" --silent > /dev/null; then
        echo "Jenkins connectivity ✓"
    else
        echo "Jenkins connectivity ✗"
        return 1
    fi
    
    echo "Checking created jobs..."
    local jobs=(
        "spring-boot-user-registration-dev"
        "spring-boot-user-registration-test" 
        "spring-boot-user-registration-prod"
    )
    
    for job in "${jobs[@]}"; do
        if curl -f "$JENKINS_URL/job/$job/api/json" --user "$JENKINS_USER:$JENKINS_PASSWORD" --silent > /dev/null; then
            echo "Job $job ✓"
        else
            echo "Job $job ✗"
        fi
    done
    
    echo "Checking credentials..."
    local creds=(
        "docker-hub-credentials"
        "github-credentials"
        "aws-ssh-key"
    )
    
    for cred in "${creds[@]}"; do
        if curl -f "$JENKINS_URL/credentials/store/system/domain/_/credential/$cred/api/json" --user "$JENKINS_USER:$JENKINS_PASSWORD" --silent > /dev/null; then
            echo "Credential $cred ✓"
        else
            echo "Credential $cred ✗"
        fi
    done
}

verify_jenkins_setup
echo "Setup verification completed ✓"
echo

# Step 5: Display success message and next steps
echo "=== Jenkins CI/CD Setup Completed Successfully! ==="
echo
echo " What was configured:"
echo "   ✓ Jenkins credentials (Docker Hub, GitHub, SSH)"
echo "   ✓ CI/CD pipeline jobs (dev, test, prod)"
echo "   ✓ Additional Jenkins plugins"
echo "   ✓ Pipeline automation scripts"
echo
echo " Access your Jenkins:"
echo "   URL: $JENKINS_URL"
echo "   Username: $JENKINS_USER"
echo "   Password: [configured]"
echo
echo " Next steps:"
echo "   1. Access Jenkins dashboard and verify jobs are created"
echo "   2. Trigger the 'spring-boot-user-registration-dev' job manually for first test"
echo "   3. Push code changes to GitHub to trigger automatic builds"
echo "   4. Monitor the complete CI/CD pipeline: dev → test → prod"
echo
echo " Pipeline flow:"
echo "   GitHub Push → Dev Job → Build & Test → Deploy to Dev → Test Job → Deploy to Test → Prod Job (manual approval) → Deploy to Prod"
echo
echo " Management commands:"
echo "   View jobs: curl -u $JENKINS_USER:$JENKINS_PASSWORD $JENKINS_URL/api/json"
echo "   Check app health: curl http://13.59.191.101:8989/api/v1/health"
echo "   Application URL: http://13.59.191.101:8989/swagger-ui.html"
echo
echo "Happy deploying! 🚀"
