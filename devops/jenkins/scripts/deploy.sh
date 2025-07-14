#!/bin/bash

# Deployment script for Spring Boot User Registration Service
# Usage: ./deploy.sh <environment> <docker_image>

set -e

ENVIRONMENT=$1
DOCKER_IMAGE=$2

if [ -z "$ENVIRONMENT" ] || [ -z "$DOCKER_IMAGE" ]; then
    echo "Usage: $0 <environment> <docker_image>"
    exit 1
fi

echo "Deploying to $ENVIRONMENT environment..."
echo "Docker image: $DOCKER_IMAGE"

# Environment-specific configuration
case $ENVIRONMENT in
    "dev")
        APP_PORT=8080
        MYSQL_DB="userdb_dev"
        PROFILE="dev"
        ;;
    "test")
        APP_PORT=8081
        MYSQL_DB="userdb_test"
        PROFILE="test"
        ;;
    "prod")
        APP_PORT=8082
        MYSQL_DB="userdb_prod"
        PROFILE="prod"
        ;;
    *)
        echo "Invalid environment: $ENVIRONMENT"
        exit 1
        ;;
esac

# Get inventory file path
INVENTORY_FILE="devops/ansible/inventory/${ENVIRONMENT}.ini"

if [ ! -f "$INVENTORY_FILE" ]; then
    echo "Inventory file not found: $INVENTORY_FILE"
    exit 1
fi

# Extract target host IP from inventory
TARGET_HOST=$(grep -A 10 "\[app_servers\]" "$INVENTORY_FILE" | grep -v "\[" | head -1 | cut -d' ' -f1)

if [ -z "$TARGET_HOST" ]; then
    echo "Could not determine target host from inventory"
    exit 1
fi

echo "Target host: $TARGET_HOST"

# SSH key path
SSH_KEY="devops/terraform/environments/${ENVIRONMENT}/user-registration-${ENVIRONMENT}-key.pem"

if [ ! -f "$SSH_KEY" ]; then
    echo "SSH key not found: $SSH_KEY"
    exit 1
fi

# Copy SSH key to /tmp with correct permissions (WSL compatibility)
cp "$SSH_KEY" /tmp/deploy_key.pem
chmod 600 /tmp/deploy_key.pem

# Create deployment directory on target host
ssh -i /tmp/deploy_key.pem -o StrictHostKeyChecking=no ubuntu@$TARGET_HOST "
    sudo mkdir -p /opt/app
    sudo chown ubuntu:ubuntu /opt/app
"

# Create docker-compose file for deployment
cat > docker-compose.${ENVIRONMENT}.yml << EOF
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    container_name: mysql-${ENVIRONMENT}
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: ${MYSQL_DB}
      MYSQL_USER: appuser
      MYSQL_PASSWORD: apppassword
    volumes:
      - mysql_data:/var/lib/mysql
    ports:
      - "3306:3306"
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      timeout: 20s
      retries: 10

  app:
    image: ${DOCKER_IMAGE}
    container_name: spring-app-${ENVIRONMENT}
    depends_on:
      mysql:
        condition: service_healthy
    environment:
      SPRING_PROFILES_ACTIVE: ${PROFILE}
      SPRING_DATASOURCE_URL: jdbc:mysql://mysql:3306/${MYSQL_DB}
      SPRING_DATASOURCE_USERNAME: appuser
      SPRING_DATASOURCE_PASSWORD: apppassword
    ports:
      - "${APP_PORT}:8080"
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 40s

volumes:
  mysql_data:

networks:
  app-network:
    driver: bridge
EOF

# Copy docker-compose file to target host
scp -i /tmp/deploy_key.pem -o StrictHostKeyChecking=no docker-compose.${ENVIRONMENT}.yml ubuntu@$TARGET_HOST:/opt/app/

# Deploy application
ssh -i /tmp/deploy_key.pem -o StrictHostKeyChecking=no ubuntu@$TARGET_HOST "
    cd /opt/app
    
    # Stop existing containers
    docker-compose -f docker-compose.${ENVIRONMENT}.yml down || true
    
    # Remove old containers and images
    docker container prune -f
    docker image prune -f
    
    # Pull latest image
    docker pull ${DOCKER_IMAGE}
    
    # Start new deployment
    docker-compose -f docker-compose.${ENVIRONMENT}.yml up -d
    
    # Wait for application to start
    echo 'Waiting for application to start...'
    for i in {1..30}; do
        if curl -f http://localhost:${APP_PORT}/actuator/health > /dev/null 2>&1; then
            echo 'Application is healthy!'
            break
        fi
        echo 'Waiting for application... (\$i/30)'
        sleep 10
    done
"

# Clean up
rm -f /tmp/deploy_key.pem
rm -f docker-compose.${ENVIRONMENT}.yml

echo "Deployment to $ENVIRONMENT completed successfully!"
