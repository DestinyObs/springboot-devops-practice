#!/bin/bash

# Jenkins Job Repository Update Script
# Updates the repository URL to the new GitHub location

source ./setup-jenkins-secrets/secrets.env

# Convert CRLF to LF if running on Windows
sed -i 's/\r$//' ./setup-jenkins-secrets/secrets.env

echo "Updating Jenkins Job Repository URL..."
echo "====================================="

# Jenkins server details
JENKINS_URL="http://${JENKINS_HOST}:${JENKINS_PORT}"
JOB_NAME="user-registration-dev"

# Get Jenkins crumb for CSRF protection
echo "Getting Jenkins CSRF token..."
CRUMB=$(curl -s -u "${JENKINS_USER}:${JENKINS_PASSWORD}" \
    "${JENKINS_URL}/crumbIssuer/api/json" | \
    jq -r '.crumb' 2>/dev/null || echo "")

if [ -n "$CRUMB" ]; then
    CRUMB_HEADER="Jenkins-Crumb: $CRUMB"
else
    CRUMB_HEADER=""
fi

# Get current job configuration
echo "Getting current job configuration..."
CURRENT_CONFIG=$(curl -s -u "${JENKINS_USER}:${JENKINS_PASSWORD}" \
    "${JENKINS_URL}/job/${JOB_NAME}/config.xml")

if [ $? -ne 0 ]; then
    echo "❌ Failed to get job configuration"
    exit 1
fi

# Update the repository URL
echo "Updating repository URL to: https://github.com/DestinyObs/springboot-devops-practice.git"
UPDATED_CONFIG=$(echo "$CURRENT_CONFIG" | sed 's|https://github.com/destinyobs/springboot-devops-practice.git|https://github.com/DestinyObs/springboot-devops-practice.git|g')

# Save updated configuration
curl -X POST -u "${JENKINS_USER}:${JENKINS_PASSWORD}" \
    -H "Content-Type: application/xml" \
    -H "$CRUMB_HEADER" \
    --data-binary "$UPDATED_CONFIG" \
    "${JENKINS_URL}/job/${JOB_NAME}/config.xml"

if [ $? -eq 0 ]; then
    echo "✅ Job repository URL updated successfully!"
    echo "New repository URL: https://github.com/DestinyObs/springboot-devops-practice.git"
else
    echo "❌ Failed to update job configuration"
    exit 1
fi

echo ""
echo "Job updated! You can now trigger a new build."
