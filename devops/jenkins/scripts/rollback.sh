#!/bin/bash

# Rollback script for production environment
# Usage: ./rollback.sh <environment>

set -e

ENVIRONMENT=$1

if [ -z "$ENVIRONMENT" ]; then
    echo "Usage: $0 <environment>"
    exit 1
fi

echo "Initiating rollback for $ENVIRONMENT environment..."

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
cp "$SSH_KEY" /tmp/rollback_key.pem
chmod 600 /tmp/rollback_key.pem

# Get previous image version
PREVIOUS_IMAGE=$(ssh -i /tmp/rollback_key.pem -o StrictHostKeyChecking=no ubuntu@$TARGET_HOST "
    docker images --format 'table {{.Repository}}\t{{.Tag}}\t{{.CreatedAt}}' | grep 'spring-boot-user-registration' | grep -v 'latest' | head -2 | tail -1 | awk '{print \$1\":\" \$2}'
")

if [ -z "$PREVIOUS_IMAGE" ]; then
    echo "No previous image found for rollback"
    exit 1
fi

echo "Rolling back to previous image: $PREVIOUS_IMAGE"

# Create rollback docker-compose file
cat > docker-compose.rollback.yml << EOF
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
    image: ${PREVIOUS_IMAGE}
    container_name: spring-app-${ENVIRONMENT}-rollback
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
scp -i /tmp/rollback_key.pem -o StrictHostKeyChecking=no docker-compose.rollback.yml ubuntu@$TARGET_HOST:/opt/app/

# Perform rollback
ssh -i /tmp/rollback_key.pem -o StrictHostKeyChecking=no ubuntu@$TARGET_HOST "
    cd /opt/app
    
    # Stop current deployment
    echo 'Stopping current deployment...'
    docker-compose -f docker-compose.${ENVIRONMENT}.yml down || true
    
    # Start rollback deployment
    echo 'Starting rollback deployment...'
    docker-compose -f docker-compose.rollback.yml up -d
    
    # Wait for rollback to be healthy
    echo 'Waiting for rollback to be healthy...'
    for i in {1..30}; do
        if curl -f http://localhost:${APP_PORT}/actuator/health > /dev/null 2>&1; then
            echo 'Rollback deployment is healthy!'
            break
        fi
        echo 'Waiting for rollback deployment... (\$i/30)'
        sleep 10
    done
    
    # Check if rollback is healthy
    if ! curl -f http://localhost:${APP_PORT}/actuator/health > /dev/null 2>&1; then
        echo 'ERROR: Rollback deployment failed'
        docker-compose -f docker-compose.rollback.yml logs app
        exit 1
    fi
    
    # Replace current deployment with rollback
    echo 'Finalizing rollback...'
    cp docker-compose.rollback.yml docker-compose.${ENVIRONMENT}.yml
    
    # Clean up failed deployment containers
    docker container prune -f
    docker image prune -f
"

# Update nginx configuration for production rollback
if [ "$ENVIRONMENT" == "prod" ]; then
    ssh -i /tmp/rollback_key.pem -o StrictHostKeyChecking=no ubuntu@$TARGET_HOST "
        # Update nginx to point to rollback deployment
        sudo tee /etc/nginx/sites-available/app-proxy > /dev/null << 'NGINX_EOF'
upstream app_backend {
    server 127.0.0.1:${APP_PORT};
}

server {
    listen ${APP_PORT};
    
    location / {
        proxy_pass http://app_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
NGINX_EOF
        
        sudo systemctl restart nginx
        echo 'Nginx configuration updated for rollback'
    "
fi

# Verify rollback
echo "Verifying rollback..."
HEALTH_STATUS=$(ssh -i /tmp/rollback_key.pem -o StrictHostKeyChecking=no ubuntu@$TARGET_HOST "
    curl -s -o /dev/null -w '%{http_code}' http://localhost:${APP_PORT}/actuator/health
")

if [ "$HEALTH_STATUS" != "200" ]; then
    echo "ERROR: Rollback verification failed (HTTP $HEALTH_STATUS)"
    exit 1
fi

# Clean up
rm -f /tmp/rollback_key.pem
rm -f docker-compose.rollback.yml

echo "Rollback completed successfully!"
echo "Application is now running on previous version: $PREVIOUS_IMAGE"
echo "Access URL: http://$TARGET_HOST:$APP_PORT"

# Create rollback summary
ssh -i "devops/terraform/environments/${ENVIRONMENT}/user-registration-${ENVIRONMENT}-key.pem" -o StrictHostKeyChecking=no ubuntu@$TARGET_HOST "
    cd /opt/app
    echo ''
    echo 'Rollback Summary:'
    echo '================='
    echo 'Environment: $ENVIRONMENT'
    echo 'Rolled back to: $PREVIOUS_IMAGE'
    echo 'Application URL: http://$TARGET_HOST:$APP_PORT'
    echo 'Status: SUCCESS'
    echo 'Running Containers:'
    docker-compose -f docker-compose.${ENVIRONMENT}.yml ps --format 'table {{.Name}}\t{{.Status}}\t{{.Ports}}'
"
