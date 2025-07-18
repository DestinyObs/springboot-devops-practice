#!/bin/bash

# Local script to create Jenkins jobs
# Run this from your local machine

JENKINS_URL="http://<DEV-INSTANCE-IP>:8080"
JENKINS_USER="admin"
JENKINS_TOKEN="<YOUR-API-TOKEN>"

echo "Creating Jenkins jobs..."

# Create dev job
curl -X POST "${JENKINS_URL}/createItem?name=user-registration-dev" \
     -H "Content-Type: application/xml" \
     --user ${JENKINS_USER}:${JENKINS_TOKEN} \
     --data '<?xml version="1.0" encoding="UTF-8"?>
<flow-definition plugin="workflow-job">
  <description>Development pipeline</description>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition">
    <scm class="hudson.plugins.git.GitSCM">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>https://github.com/destinyobs/springboot-devops-practice.git</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
    </scm>
    <scriptPath>devops/jenkins/pipelines/Jenkinsfile.dev</scriptPath>
  </definition>
  <triggers>
    <com.cloudbees.jenkins.GitHubPushTrigger>
      <spec></spec>
    </com.cloudbees.jenkins.GitHubPushTrigger>
  </triggers>
</flow-definition>'

echo "Job created! Access Jenkins at: ${JENKINS_URL}"
