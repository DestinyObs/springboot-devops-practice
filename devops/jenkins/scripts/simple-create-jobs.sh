#!/bin/bash

# Simplified Jenkins job creation script
# Usage: ./simple-create-jobs.sh

set -e

echo "Creating Jenkins jobs (simplified approach)..."

# Jenkins connection details
JENKINS_URL="http://13.59.191.101:8080"
JENKINS_USER="admin"
JENKINS_PASSWORD="859ce99d4dcb4f9d8ca5834422e9903a"

# Get Jenkins crumb for CSRF protection
echo "Getting Jenkins CSRF token..."
CRUMB_HEADER=$(curl -s "$JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)" \
    --user "$JENKINS_USER:$JENKINS_PASSWORD")
echo "CSRF token: $CRUMB_HEADER"

# Function to create a simple Jenkins pipeline job
create_simple_job() {
    local JOB_NAME=$1
    local JENKINSFILE_PATH=$2
    local DESCRIPTION=$3
    
    echo "Creating job: $JOB_NAME"
    
    # Simple job configuration XML
    cat > "${JOB_NAME}.xml" << EOF
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.40">
  <actions/>
  <description>$DESCRIPTION</description>
  <keepDependencies>false</keepDependencies>
  <properties/>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.87">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@4.7.1">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>https://github.com/destinyobs/springboot-devops-practice.git</url>
          <credentialsId>github-credentials</credentialsId>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="list"/>
      <extensions/>
    </scm>
    <scriptPath>$JENKINSFILE_PATH</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF
    
    # Create the job
    curl -X POST "$JENKINS_URL/createItem?name=$JOB_NAME" \
        --user "$JENKINS_USER:$JENKINS_PASSWORD" \
        --header "$CRUMB_HEADER" \
        --header "Content-Type: application/xml" \
        --data-binary @"${JOB_NAME}.xml" \
        -w "\nHTTP Status: %{http_code}\n"
    
    # Check if job was created
    sleep 2
    if curl -f "$JENKINS_URL/job/$JOB_NAME/api/json" --user "$JENKINS_USER:$JENKINS_PASSWORD" --silent > /dev/null 2>&1; then
        echo "✅ Job $JOB_NAME created successfully!"
    else
        echo "❌ Failed to create job $JOB_NAME"
    fi
    
    # Clean up
    rm -f "${JOB_NAME}.xml"
}

# Create the jobs
create_simple_job "user-registration-dev" "devops/jenkins/pipelines/Jenkinsfile.dev" "Development CI/CD Pipeline"
create_simple_job "user-registration-test" "devops/jenkins/pipelines/Jenkinsfile.test" "Test Environment Pipeline"  
create_simple_job "user-registration-prod" "devops/jenkins/pipelines/Jenkinsfile.prod" "Production Deployment Pipeline"

echo ""
echo "🎉 Job creation completed!"
echo ""
echo "Next steps:"
echo "1. Refresh your Jenkins dashboard at: $JENKINS_URL"
echo "2. You should see the three new jobs created"
echo "3. Click on 'user-registration-dev' and then 'Build Now' to test"
echo ""
echo "Jobs created:"
echo "- user-registration-dev"
echo "- user-registration-test" 
echo "- user-registration-prod"
