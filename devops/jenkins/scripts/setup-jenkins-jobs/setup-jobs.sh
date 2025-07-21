#!/bin/bash

# Load environment variables from jobs.env file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/jobs.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: jobs.env file not found at $ENV_FILE"
    echo "Please copy jobs.env.example to jobs.env and fill in your actual configuration"
    exit 1
fi

# Load environment variables with line ending cleanup
while IFS='=' read -r key value; do
    # Skip empty lines and comments
    [[ $key =~ ^#.*$ ]] && continue
    [[ -z "$key" ]] && continue
    
    # Clean up key and value from any carriage returns
    key=$(echo "$key" | tr -d '\r\n')
    value=$(echo "$value" | tr -d '\r')
    
    # Export the variable
    export "$key=$value"
done < "$ENV_FILE"

echo "Loaded configuration from $ENV_FILE"
echo "Jenkins URL: $JENKINS_URL"
echo "Creating jobs for: $DEV_JOB_NAME, $TEST_JOB_NAME, $PROD_JOB_NAME"

# Create a temporary cookie jar
COOKIE_JAR=$(mktemp)
trap "rm -f $COOKIE_JAR" EXIT

# Function to create jobs using proper API
create_job() {
    local job_name="$1"
    local job_xml="$2"
    
    echo "Creating job: $job_name"
    
    # Get CSRF token
    local crumb=$(curl -s --cookie-jar "$COOKIE_JAR" --cookie "$COOKIE_JAR" \
        -u "$JENKINS_USER:$JENKINS_PASSWORD" \
        "$JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")
    
    echo "Got crumb: $crumb"
    
    # Create the job
    local response=$(curl -s -w "%{http_code}" --cookie-jar "$COOKIE_JAR" --cookie "$COOKIE_JAR" \
        -u "$JENKINS_USER:$JENKINS_PASSWORD" \
        -H "$crumb" \
        -H "Content-Type: application/xml" \
        -X POST \
        -d "$job_xml" \
        "$JENKINS_URL/createItem?name=$job_name")
    
    local http_code="${response: -3}"
    local body="${response%???}"
    
    if [[ "$http_code" == "200" ]]; then
        echo "✓ Job $job_name created successfully"
    else
        echo "✗ Failed to create job $job_name (HTTP: $http_code)"
        echo "Response: $body"
        return 1
    fi
}

echo "Setting up Jenkins CI/CD Pipeline Jobs..."

# Create Development Job
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

create_job "$DEV_JOB_NAME" "$DEV_JOB_XML"

# Create Test Job
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

create_job "$TEST_JOB_NAME" "$TEST_JOB_XML"

# Create Production Job  
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

create_job "$PROD_JOB_NAME" "$PROD_JOB_XML"

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
echo ""
echo "Verifying jobs were created..."
curl -s -u "$JENKINS_USER:$JENKINS_PASSWORD" "$JENKINS_URL/api/json?tree=jobs[name]" | grep -o '"name":"[^"]*"' || echo "No jobs found or API call failed"
