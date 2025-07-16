#!/bin/bash

# Jenkins job creation script
# Usage: ./create-jenkins-jobs.sh

set -e

echo "Creating Jenkins jobs for Spring Boot User Registration Service..."

# Jenkins connection details
JENKINS_URL="http://localhost:8080"
JENKINS_USER="admin"
JENKINS_PASSWORD="admin123"

# Function to create Jenkins job
create_jenkins_job() {
    local JOB_NAME=$1
    local JOB_CONFIG=$2
    
    echo "Creating Jenkins job: $JOB_NAME"
    
    curl -X POST "$JENKINS_URL/createItem?name=$JOB_NAME" \
        --user "$JENKINS_USER:$JENKINS_PASSWORD" \
        --header "Content-Type: application/xml" \
        --data-binary @"$JOB_CONFIG"
    
    echo "Job $JOB_NAME created successfully"
}

# Dev job configuration
cat > job-dev.xml << 'EOF'
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.40">
  <actions/>
  <description>Development environment CI/CD pipeline for Spring Boot User Registration Service</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <com.cloudbees.jenkins.GitHubPushTrigger plugin="github@1.33.1">
          <spec></spec>
        </com.cloudbees.jenkins.GitHubPushTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.87">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@4.7.1">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>https://github.com/your-username/springboot-devops-practice.git</url>
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
    <scriptPath>devops/jenkins/pipelines/Jenkinsfile.dev</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF

# Test job configuration
cat > job-test.xml << 'EOF'
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.40">
  <actions/>
  <description>Test environment CI/CD pipeline for Spring Boot User Registration Service</description>
  <keepDependencies>false</keepDependencies>
  <properties/>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.87">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@4.7.1">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>https://github.com/your-username/springboot-devops-practice.git</url>
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
    <scriptPath>devops/jenkins/pipelines/Jenkinsfile.test</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF

# Prod job configuration
cat > job-prod.xml << 'EOF'
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.40">
  <actions/>
  <description>Production environment CI/CD pipeline for Spring Boot User Registration Service</description>
  <keepDependencies>false</keepDependencies>
  <properties/>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.87">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@4.7.1">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>https://github.com/your-username/springboot-devops-practice.git</url>
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
    <scriptPath>devops/jenkins/pipelines/Jenkinsfile.prod</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF

# Create jobs
create_jenkins_job "spring-boot-user-registration-dev" "job-dev.xml"
create_jenkins_job "spring-boot-user-registration-test" "job-test.xml"
create_jenkins_job "spring-boot-user-registration-prod" "job-prod.xml"

# Clean up
rm -f job-dev.xml job-test.xml job-prod.xml

echo "All Jenkins jobs created successfully!"
echo "Jobs created:"
echo "- spring-boot-user-registration-dev (triggered by GitHub push)"
echo "- spring-boot-user-registration-test (triggered by dev success)"
echo "- spring-boot-user-registration-prod (triggered by test approval)"
