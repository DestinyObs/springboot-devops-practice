#!/bin/bash

# Load environment variables from jobs.env file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/jobs.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: jobs.env file not found at $ENV_FILE"
    echo "Please copy jobs.env.example to jobs.env and fill in your actual configuration"
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
        -H "Content-Type: ${content_type:-application/xml}" \
        -X "$method" \
        ${data:+--data-binary "$data"} \
        "$JENKINS_URL$endpoint"
}

echo "Setting up Jenkins CI/CD Pipeline Jobs..."

# Function to create Jenkins job
create_jenkins_job() {
    local JOB_NAME=$1
    local JOB_CONFIG=$2
    
    echo "Creating Jenkins job: $JOB_NAME"
    
    # Check if job already exists
    if curl -f "$JENKINS_URL/job/$JOB_NAME/api/json" --user "$JENKINS_USER:$JENKINS_PASSWORD" --silent > /dev/null 2>&1; then
        echo "Job $JOB_NAME already exists, updating configuration..."
        curl -X POST "$JENKINS_URL/job/$JOB_NAME/config.xml" \
            --user "$JENKINS_USER:$JENKINS_PASSWORD" \
            --header "$JENKINS_CRUMB" \
            --header "Content-Type: application/xml" \
            --data-binary @"$JOB_CONFIG" \
            --silent
        echo "Job $JOB_NAME updated successfully ✓"
    else
        echo "Creating new job $JOB_NAME..."
        RESPONSE=$(curl -X POST "$JENKINS_URL/createItem?name=$JOB_NAME" \
            --user "$JENKINS_USER:$JENKINS_PASSWORD" \
            --header "$JENKINS_CRUMB" \
            --header "Content-Type: application/xml" \
            --data-binary @"$JOB_CONFIG" \
            2>&1)
        
        if [[ $? -eq 0 ]]; then
            echo "Job $JOB_NAME created successfully ✓"
        else
            echo "Failed to create job $JOB_NAME"
            echo "Response: $RESPONSE"
        fi
    fi
}

# Create Development Job
echo "Creating Development Pipeline Job..."
DEV_JOB_XML='<?xml version="1.1" encoding="UTF-8"?>
<flow-definition plugin="workflow-job">
  <actions/>
  <description>Development Pipeline - Triggered by GitHub push to main branch</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <com.cloudbees.jenkins.GitHubPushTrigger plugin="github">
          <spec></spec>
        </com.cloudbees.jenkins.GitHubPushTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps">
    <scm class="hudson.plugins.git.GitSCM" plugin="git">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>'"$GITHUB_REPO_URL"'</url>
          <credentialsId>github-credentials</credentialsId>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/'"$GITHUB_BRANCH"'</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="empty-list"/>
      <extensions/>
    </scm>
    <scriptPath>devops/jenkins/pipelines/Jenkinsfile.dev</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>'

jenkins_request "POST" "/createItem?name=$DEV_JOB_NAME" "$DEV_JOB_XML"
echo "Development job created successfully!"

# Create Test Job
echo "Creating Test Pipeline Job..."
TEST_JOB_XML='<?xml version="1.1" encoding="UTF-8"?>
<flow-definition plugin="workflow-job">
  <actions/>
  <description>Test Pipeline - Triggered by successful Dev build</description>
  <keepDependencies>false</keepDependencies>
  <properties/>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps">
    <scm class="hudson.plugins.git.GitSCM" plugin="git">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>'"$GITHUB_REPO_URL"'</url>
          <credentialsId>github-credentials</credentialsId>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/'"$GITHUB_BRANCH"'</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="empty-list"/>
      <extensions/>
    </scm>
    <scriptPath>devops/jenkins/pipelines/Jenkinsfile.test</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>'

jenkins_request "POST" "/createItem?name=$TEST_JOB_NAME" "$TEST_JOB_XML"
echo "Test job created successfully!"

# Create Production Job
echo "Creating Production Pipeline Job..."
PROD_JOB_XML='<?xml version="1.1" encoding="UTF-8"?>
<flow-definition plugin="workflow-job">
  <actions/>
  <description>Production Pipeline - Manual approval required</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <hudson.model.ParametersDefinitionProperty>
      <parameterDefinitions>
        <hudson.model.StringParameterDefinition>
          <name>IMAGE_TAG</name>
          <description>Docker image tag to deploy to production</description>
          <defaultValue></defaultValue>
        </hudson.model.StringParameterDefinition>
      </parameterDefinitions>
    </hudson.model.ParametersDefinitionProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps">
    <scm class="hudson.plugins.git.GitSCM" plugin="git">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>'"$GITHUB_REPO_URL"'</url>
          <credentialsId>github-credentials</credentialsId>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/'"$GITHUB_BRANCH"'</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="empty-list"/>
      <extensions/>
    </scm>
    <scriptPath>devops/jenkins/pipelines/Jenkinsfile.prod</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>'

jenkins_request "POST" "/createItem?name=$PROD_JOB_NAME" "$PROD_JOB_XML"
echo "Production job created successfully!"

echo ""
echo "🚀 All Jenkins CI/CD Pipeline Jobs Created Successfully!"
echo ""
echo "Jobs created:"
echo "1. user-registration-dev   - Development pipeline (GitHub push trigger)"
echo "2. user-registration-test  - Test pipeline (triggered by dev success)"
echo "3. user-registration-prod  - Production pipeline (manual approval)"
echo ""
echo "Pipeline Flow:"
echo "GitHub Push → Dev Build → Test Build → Manual Approval → Production Deploy"
echo ""
echo "Access your jobs at: $JENKINS_URL"
