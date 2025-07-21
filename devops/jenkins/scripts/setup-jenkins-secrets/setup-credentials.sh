#!/bin/bash

# Load environment variables from secrets.env file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/secrets.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: secrets.env file not found at $ENV_FILE"
    echo "Please copy secrets.env.example to secrets.env and fill in your actual credentials"
    exit 1
fi

# Load environment variables
set -a  # automatically export all variables
source "$ENV_FILE"
set +a

echo "Loaded configuration from $ENV_FILE"

# Create a temporary cookie jar
COOKIE_JAR=$(mktemp)
trap "rm -f $COOKIE_JAR" EXIT

# Function to make authenticated requests
jenkins_request() {
    local method="$1"
    local endpoint="$2"
    local data="$3"
    local content_type="$4"
    
    # Get fresh crumb with cookies
    local crumb=$(curl -s --cookie-jar "$COOKIE_JAR" --cookie "$COOKIE_JAR" \
        -u "$JENKINS_USER:$JENKINS_PASSWORD" \
        "$JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")
    
    # Make the actual request with cookies and crumb
    curl -s --cookie-jar "$COOKIE_JAR" --cookie "$COOKIE_JAR" \
        -u "$JENKINS_USER:$JENKINS_PASSWORD" \
        -H "$crumb" \
        -H "Content-Type: ${content_type:-application/x-www-form-urlencoded}" \
        -X "$method" \
        ${data:+-d "$data"} \
        "$JENKINS_URL$endpoint"
}

echo "Setting up Jenkins credentials..."

# Create Docker Hub credentials
echo "Creating Docker Hub credentials..."
jenkins_request "POST" "/credentials/store/system/domain/_/createCredentials" \
    "json={\"\":\"0\",\"credentials\":{\"scope\":\"GLOBAL\",\"id\":\"docker-hub-credentials\",\"description\":\"Docker Hub Registry Access\",\"username\":\"$DOCKER_USERNAME\",\"password\":\"$DOCKER_PASSWORD\",\"\$class\":\"com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl\"}}"

echo "Docker Hub credentials created."

# Create GitHub credentials  
echo "Creating GitHub credentials..."
jenkins_request "POST" "/credentials/store/system/domain/_/createCredentials" \
    "json={\"\":\"0\",\"credentials\":{\"scope\":\"GLOBAL\",\"id\":\"github-credentials\",\"description\":\"GitHub Repository Access\",\"username\":\"$GITHUB_USERNAME\",\"password\":\"$GITHUB_TOKEN\",\"\$class\":\"com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl\"}}"

echo "GitHub credentials created."

# Create SSH Key credentials
echo "Creating SSH key credentials..."
SSH_KEY_CONTENT=$(cat "$SSH_KEY_PATH" | sed 's/$/\\n/' | tr -d '\n' | sed 's/\\n$//')
jenkins_request "POST" "/credentials/store/system/domain/_/createCredentials" \
    "json={\"\":\"0\",\"credentials\":{\"scope\":\"GLOBAL\",\"id\":\"aws-ssh-key\",\"description\":\"AWS EC2 SSH Access\",\"username\":\"ubuntu\",\"privateKeySource\":{\"privateKey\":\"$SSH_KEY_CONTENT\",\"\$class\":\"com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey\$DirectEntryPrivateKeySource\"},\"\$class\":\"com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey\"}}"

echo "SSH key credentials created."

echo "All credentials created successfully!"
