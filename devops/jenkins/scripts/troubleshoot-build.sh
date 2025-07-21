#!/bin/bash

# Jenkins Build Troubleshooting Script
# This script helps diagnose Jenkins build failures

source ./setup-jenkins-secrets/secrets.env

# Convert CRLF to LF if running on Windows
sed -i 's/\r$//' ./setup-jenkins-secrets/secrets.env

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

echo "Checking Jenkins job status..."

# Get last build info
BUILD_INFO=$(curl -s -u "${JENKINS_USER}:${JENKINS_PASSWORD}" \
    "${JENKINS_URL}/job/${JOB_NAME}/lastBuild/api/json")

if [ $? -eq 0 ]; then
    echo ""
    echo "Last Build Information:"
    echo "======================"
    
    BUILD_NUMBER=$(echo "$BUILD_INFO" | jq -r '.number // "N/A"')
    BUILD_RESULT=$(echo "$BUILD_INFO" | jq -r '.result // "IN_PROGRESS"')
    BUILD_TIMESTAMP=$(echo "$BUILD_INFO" | jq -r '.timestamp // 0')
    BUILD_DURATION=$(echo "$BUILD_INFO" | jq -r '.duration // 0')
    
    if [ "$BUILD_TIMESTAMP" != "0" ]; then
        BUILD_TIME=$(date -d "@$((BUILD_TIMESTAMP / 1000))" 2>/dev/null || echo "Unknown")
    else
        BUILD_TIME="Unknown"
    fi
    
    echo "Build Number: $BUILD_NUMBER"
    echo "Result: $BUILD_RESULT"
    echo "Started: $BUILD_TIME"
    echo "Duration: $((BUILD_DURATION / 1000)) seconds"
    echo ""
    
    # Get console output for failed builds
    if [ "$BUILD_RESULT" = "FAILURE" ]; then
        echo "Getting console output for failed build..."
        echo "========================================="
        
        CONSOLE_OUTPUT=$(curl -s -u "${JENKINS_USER}:${JENKINS_PASSWORD}" \
            "${JENKINS_URL}/job/${JOB_NAME}/lastBuild/consoleText")
        
        # Show last 50 lines of console output
        echo "$CONSOLE_OUTPUT" | tail -50
        echo ""
        echo "Full console output available at: ${JENKINS_URL}/job/${JOB_NAME}/lastBuild/console"
    fi
    
    # Check if job configuration is correct
    echo "Checking job configuration..."
    JOB_CONFIG=$(curl -s -u "${JENKINS_USER}:${JENKINS_PASSWORD}" \
        "${JENKINS_URL}/job/${JOB_NAME}/config.xml")
    
    # Check if GitHub webhook is configured
    if echo "$JOB_CONFIG" | grep -q "GitHubPushTrigger"; then
        echo "GitHub webhook trigger is configured"
    else
        echo "GitHub webhook trigger is NOT configured"
        echo "   Run setup-webhook.sh to fix this"
    fi
    
    # Check repository URL
    REPO_URL=$(echo "$JOB_CONFIG" | grep -oP '(?<=<url>)[^<]+' | head -1)
    echo "Repository URL: $REPO_URL"
    
    if echo "$REPO_URL" | grep -q "DestinyObs"; then
        echo "Repository URL is correct"
    else
        echo "Repository URL needs updating"
    fi
    
else
    echo "Failed to connect to Jenkins or job doesn't exist"
    echo "Check if Jenkins is running at: $JENKINS_URL"
    echo "Check if job '$JOB_NAME' exists"
fi

echo ""
echo "Jenkins Dashboard: $JENKINS_URL"
echo "Job URL: ${JENKINS_URL}/job/${JOB_NAME}/"
