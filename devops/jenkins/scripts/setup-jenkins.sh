#!/bin/bash

# Jenkins initial setup script
# Usage: ./setup-jenkins.sh

set -e

echo "Setting up Jenkins for Spring Boot User Registration Service..."

# Jenkins connection details
JENKINS_URL="http://localhost:8080"
JENKINS_USER="admin"
JENKINS_PASSWORD="admin123"

# Function to install Jenkins plugin
install_plugin() {
    local PLUGIN_NAME=$1
    echo "Installing plugin: $PLUGIN_NAME"
    
    curl -X POST "$JENKINS_URL/pluginManager/installNecessaryPlugins" \
        --user "$JENKINS_USER:$JENKINS_PASSWORD" \
        --data-urlencode "plugin=$PLUGIN_NAME"
}

# Function to create Jenkins credential
create_credential() {
    local CREDENTIAL_ID=$1
    local USERNAME=$2
    local PASSWORD=$3
    local DESCRIPTION=$4
    
    echo "Creating credential: $CREDENTIAL_ID"
    
    cat > credential.xml << EOF
<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>$CREDENTIAL_ID</id>
  <description>$DESCRIPTION</description>
  <username>$USERNAME</username>
  <password>$PASSWORD</password>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
EOF
    
    curl -X POST "$JENKINS_URL/credentials/store/system/domain/_/createCredentials" \
        --user "$JENKINS_USER:$JENKINS_PASSWORD" \
        --header "Content-Type: application/xml" \
        --data-binary @credential.xml
    
    rm -f credential.xml
}

# Function to configure Maven
configure_maven() {
    echo "Configuring Maven..."
    
    cat > maven-config.xml << 'EOF'
<hudson.tasks.Maven_-MavenInstallation>
  <name>Maven-3.9.6</name>
  <home>/usr/share/maven</home>
  <properties>
    <hudson.tools.InstallSourceProperty>
      <installers>
        <hudson.tasks.Maven_-MavenInstaller>
          <id>3.9.6</id>
        </hudson.tasks.Maven_-MavenInstaller>
      </installers>
    </hudson.tools.InstallSourceProperty>
  </properties>
</hudson.tasks.Maven_-MavenInstallation>
EOF
    
    curl -X POST "$JENKINS_URL/configureTools/configureMaven" \
        --user "$JENKINS_USER:$JENKINS_PASSWORD" \
        --header "Content-Type: application/xml" \
        --data-binary @maven-config.xml
    
    rm -f maven-config.xml
}

# Function to configure JDK
configure_jdk() {
    echo "Configuring JDK..."
    
    cat > jdk-config.xml << 'EOF'
<hudson.model.JDK>
  <name>OpenJDK-17</name>
  <home>/usr/lib/jvm/java-17-openjdk-amd64</home>
  <properties>
    <hudson.tools.InstallSourceProperty>
      <installers>
        <hudson.tools.JDKInstaller>
          <id>jdk-17.0.2</id>
          <acceptLicense>true</acceptLicense>
        </hudson.tools.JDKInstaller>
      </installers>
    </hudson.tools.InstallSourceProperty>
  </properties>
</hudson.model.JDK>
EOF
    
    curl -X POST "$JENKINS_URL/configureTools/configureJDK" \
        --user "$JENKINS_USER:$JENKINS_PASSWORD" \
        --header "Content-Type: application/xml" \
        --data-binary @jdk-config.xml
    
    rm -f jdk-config.xml
}

# Wait for Jenkins to be ready
echo "Waiting for Jenkins to be ready..."
for i in {1..30}; do
    if curl -f "$JENKINS_URL/login" > /dev/null 2>&1; then
        echo "Jenkins is ready!"
        break
    fi
    echo "Waiting for Jenkins... ($i/30)"
    sleep 10
done

# Install required plugins
echo "Installing required plugins..."
install_plugin "workflow-aggregator"
install_plugin "git"
install_plugin "github"
install_plugin "docker-workflow"
install_plugin "pipeline-stage-view"
install_plugin "build-pipeline-plugin"
install_plugin "test-results-analyzer"
install_plugin "jacoco"

# Wait for plugins to install
echo "Waiting for plugins to install..."
sleep 30

# Configure tools
configure_maven
configure_jdk

# Create Docker Hub credentials
echo "Please enter your Docker Hub credentials:"
read -p "Docker Hub username: " DOCKER_USERNAME
read -s -p "Docker Hub password: " DOCKER_PASSWORD
echo

create_credential "docker-hub-credentials" "$DOCKER_USERNAME" "$DOCKER_PASSWORD" "Docker Hub credentials for image push"

# Create GitHub credentials (if needed)
read -p "Do you want to add GitHub credentials? (y/n): " ADD_GITHUB
if [ "$ADD_GITHUB" == "y" ]; then
    read -p "GitHub username: " GITHUB_USERNAME
    read -s -p "GitHub token: " GITHUB_TOKEN
    echo
    
    create_credential "github-credentials" "$GITHUB_USERNAME" "$GITHUB_TOKEN" "GitHub credentials for repository access"
fi

# Restart Jenkins to apply changes
echo "Restarting Jenkins to apply changes..."
curl -X POST "$JENKINS_URL/restart" \
    --user "$JENKINS_USER:$JENKINS_PASSWORD"

echo "Jenkins setup completed successfully!"
echo "Please wait for Jenkins to restart, then run create-jenkins-jobs.sh to create the CI/CD jobs."
