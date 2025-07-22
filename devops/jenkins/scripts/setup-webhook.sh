#!/bin/bash

# Jenkins Webhook Configuration Script
# This script configures GitHub webhook integration for automatic builds

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the secrets file
source "$SCRIPT_DIR/setup-jenkins-secrets/secrets.env"

# Convert CRLF to LF if running on Windows
sed -i 's/\r$//' "$SCRIPT_DIR/setup-jenkins-secrets/secrets.env"

echo "Setting up Jenkins webhook integration..."

# Jenkins server details
JENKINS_URL="http://${JENKINS_HOST}:${JENKINS_PORT}"
JOB_NAME="user-registration-dev"

# Get Jenkins crumb for CSRF protection using cookie jar
echo "Getting Jenkins CSRF token..."
COOKIE_JAR=$(mktemp)
CRUMB=$(curl -c "$COOKIE_JAR" -s -u "${JENKINS_USER}:${JENKINS_PASSWORD}" \
    "${JENKINS_URL}/crumbIssuer/api/json" | \
    jq -r '.crumb' 2>/dev/null || echo "")

if [ -n "$CRUMB" ]; then
    CRUMB_HEADER="Jenkins-Crumb: $CRUMB"
else
    CRUMB_HEADER=""
fi

# Update job configuration to enable GitHub webhook trigger
echo "Configuring job to accept webhook triggers..."

# Job XML configuration with GitHub webhook trigger
cat > job_config_webhook.xml << 'EOF'
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@1400.v7fd111b_ec82f">
  <actions>
    <org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobAction plugin="pipeline-model-definition@2.2214.vb_b_34b_2ea_9b_83"/>
    <org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobPropertyTrackerAction plugin="pipeline-model-definition@2.2214.vb_b_34b_2ea_9b_83">
      <jobProperties/>
      <triggers/>
      <parameters/>
      <options/>
    </org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobPropertyTrackerAction>
  </actions>
  <description>Development environment pipeline with GitHub webhook integration</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <com.cloudbees.jenkins.GitHubPushTrigger plugin="github@1.40.0">
          <spec></spec>
        </com.cloudbees.jenkins.GitHubPushTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@3950.va_633fd463855">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@5.5.2">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>https://github.com/DestinyObs/springboot-devops-practice.git</url>
          <credentialsId>github-credentials</credentialsId>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
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
</flow-definition>
EOF

# Update the job configuration
echo "Updating job configuration with webhook trigger..."
curl -X POST -b "$COOKIE_JAR" -u "${JENKINS_USER}:${JENKINS_PASSWORD}" \
    -H "Content-Type: application/xml" \
    -H "$CRUMB_HEADER" \
    --data-binary @job_config_webhook.xml \
    "${JENKINS_URL}/job/${JOB_NAME}/config.xml"

if [ $? -eq 0 ]; then
    echo "✅ Job configuration updated successfully!"
else
    echo "Failed to update job configuration"
    rm -f "$COOKIE_JAR"
    exit 1
fi

# Clean up
rm -f job_config_webhook.xml "$COOKIE_JAR"

echo ""
echo "🔗 Webhook Configuration Complete!"
echo ""
echo "Next steps:"
echo "1. Go to your GitHub repository: https://github.com/DestinyObs/springboot-devops-practice"
echo "2. Navigate to Settings > Webhooks > Add webhook"
echo "3. Set Payload URL: ${JENKINS_URL}/github-webhook/"
echo "4. Content type: application/json"
echo "5. Select 'Just the push event'"
echo "6. Make sure webhook is Active"
echo ""
echo "Jenkins job will now trigger automatically on git push!"
