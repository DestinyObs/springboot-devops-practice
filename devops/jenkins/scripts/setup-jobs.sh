#!/bin/bash

# Jenkins Jobs Setup Script

JENKINS_URL="http://localhost:8081"
JENKINS_USER="admin"
JENKINS_PASSWORD="admin"

echo "Creating Jenkins jobs for user-registration microservice..."

# Create Dev Job
curl -s -X POST "${JENKINS_URL}/createItem?name=user-registration-dev" \
     -H "Content-Type: application/xml" \
     --user ${JENKINS_USER}:${JENKINS_PASSWORD} \
     --data-binary @- << EOF
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.40">
  <description>Development pipeline for user registration microservice</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <com.cloudbees.jenkins.GitHubPushTrigger plugin="github@1.34.1">
          <spec></spec>
        </com.cloudbees.jenkins.GitHubPushTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.92">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@4.8.3">
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
    <lightweight>true</lightweight>
  </definition>
</flow-definition>
EOF

# Create Test Job
curl -s -X POST "${JENKINS_URL}/createItem?name=user-registration-test" \
     -H "Content-Type: application/xml" \
     --user ${JENKINS_USER}:${JENKINS_PASSWORD} \
     --data-binary @- << EOF
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.40">
  <description>Test pipeline for user registration microservice</description>
  <keepDependencies>false</keepDependencies>
  <properties/>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.92">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@4.8.3">
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
    <scriptPath>devops/jenkins/pipelines/Jenkinsfile.test</scriptPath>
    <lightweight>true</lightweight>
  </definition>
</flow-definition>
EOF

# Create Prod Job
curl -s -X POST "${JENKINS_URL}/createItem?name=user-registration-prod" \
     -H "Content-Type: application/xml" \
     --user ${JENKINS_USER}:${JENKINS_PASSWORD} \
     --data-binary @- << EOF
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.40">
  <description>Production pipeline for user registration microservice</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <hudson.model.ParametersDefinitionProperty>
      <parameterDefinitions>
        <hudson.model.StringParameterDefinition>
          <name>IMAGE_TAG</name>
          <description>Docker image tag to deploy</description>
          <defaultValue></defaultValue>
          <trim>false</trim>
        </hudson.model.StringParameterDefinition>
      </parameterDefinitions>
    </hudson.model.ParametersDefinitionProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.92">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@4.8.3">
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
    <scriptPath>devops/jenkins/pipelines/Jenkinsfile.prod</scriptPath>
    <lightweight>true</lightweight>
  </definition>
</flow-definition>
EOF

echo "Jenkins jobs created successfully!"
echo "Access Jenkins at: ${JENKINS_URL}"
