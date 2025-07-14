#!/bin/bash

# Blue-Green deployment script for Production environment
# Usage: ./blue-green-deploy.sh <environment> <docker_image>

set -e

ENVIRONMENT=$1
DOCKER_IMAGE=$2

if [ -z "$ENVIRONMENT" ] || [ -z "$DOCKER_IMAGE" ]; then
    echo "Usage: $0 <environment> <docker_image>"
    exit 1
fi

if [ "$ENVIRONMENT" != "prod" ]; then
    echo "Blue-Green deployment is only for production environment"
    exit 1
fi

echo "Starting Blue-Green deployment for production..."
echo "Docker image: $DOCKER_IMAGE"

APP_PORT=8082
MYSQL_DB="userdb_prod"
PROFILE="prod"

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
cp "$SSH_KEY" /tmp/blue_green_key.pem
chmod 600 /tmp/blue_green_key.pem

# Create blue-green docker-compose file
cat > docker-compose.blue-green.yml << EOF
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    container_name: mysql-prod
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

  app-blue:
    image: ${DOCKER_IMAGE}
    container_name: spring-app-blue
    depends_on:
      mysql:
        condition: service_healthy
    environment:
      SPRING_PROFILES_ACTIVE: ${PROFILE}
      SPRING_DATASOURCE_URL: jdbc:mysql://mysql:3306/${MYSQL_DB}
      SPRING_DATASOURCE_USERNAME: appuser
      SPRING_DATASOURCE_PASSWORD: apppassword
    ports:
      - "8083:8080"
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 40s

  app-green:
    image: ${DOCKER_IMAGE}
    container_name: spring-app-green
    depends_on:
      mysql:
        condition: service_healthy
    environment:
      SPRING_PROFILES_ACTIVE: ${PROFILE}
      SPRING_DATASOURCE_URL: jdbc:mysql://mysql:3306/${MYSQL_DB}
      SPRING_DATASOURCE_USERNAME: appuser
      SPRING_DATASOURCE_PASSWORD: apppassword
    ports:
      - "8084:8080"
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
scp -i /tmp/blue_green_key.pem -o StrictHostKeyChecking=no docker-compose.blue-green.yml ubuntu@$TARGET_HOST:/opt/app/

# Deploy new version to green environment
ssh -i /tmp/blue_green_key.pem -o StrictHostKeyChecking=no ubuntu@$TARGET_HOST "
    cd /opt/app
    
    # Start green environment
    echo 'Starting green environment...'
    docker-compose -f docker-compose.blue-green.yml up -d app-green
    
    # Wait for green environment to be healthy
    echo 'Waiting for green environment to be healthy...'
    for i in {1..30}; do
        if curl -f http://localhost:8084/actuator/health > /dev/null 2>&1; then
            echo 'Green environment is healthy!'
            break
        fi
        echo 'Waiting for green environment... (\$i/30)'
        sleep 10
    done
    
    # Check if green environment is healthy
    if ! curl -f http://localhost:8084/actuator/health > /dev/null 2>&1; then
        echo 'ERROR: Green environment failed to start'
        docker-compose -f docker-compose.blue-green.yml logs app-green
        exit 1
    fi
"

# Switch traffic from blue to green
ssh -i /tmp/blue_green_key.pem -o StrictHostKeyChecking=no ubuntu@$TARGET_HOST "
    cd /opt/app
    
    # Install nginx if not present
    if ! command -v nginx &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y nginx
    fi
    
    # Create nginx configuration for blue-green switching
    sudo tee /etc/nginx/sites-available/app-proxy > /dev/null << 'NGINX_EOF'
upstream app_backend {
    server 127.0.0.1:8084;  # Green environment
}

server {
    listen 8082;
    
    location / {
        proxy_pass http://app_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
NGINX_EOF
    
    # Enable the site
    sudo ln -sf /etc/nginx/sites-available/app-proxy /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Test nginx configuration
    sudo nginx -t
    
    # Restart nginx
    sudo systemctl restart nginx
    sudo systemctl enable nginx
    
    echo 'Traffic switched to green environment'
"

# Verify deployment
echo "Verifying deployment..."
HEALTH_STATUS=$(ssh -i /tmp/blue_green_key.pem -o StrictHostKeyChecking=no ubuntu@$TARGET_HOST "
    curl -s -o /dev/null -w '%{http_code}' http://localhost:8082/actuator/health
")

if [ "$HEALTH_STATUS" != "200" ]; then
    echo "ERROR: Blue-Green deployment failed (HTTP $HEALTH_STATUS)"
    echo "Rolling back to blue environment..."
    
    ssh -i /tmp/blue_green_key.pem -o StrictHostKeyChecking=no ubuntu@$TARGET_HOST "
        cd /opt/app
        
        # Switch back to blue
        sudo tee /etc/nginx/sites-available/app-proxy > /dev/null << 'NGINX_EOF'
upstream app_backend {
    server 127.0.0.1:8083;  # Blue environment
}

server {
    listen 8082;
    
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
        echo 'Rolled back to blue environment'
    "
    
    exit 1
fi

# Clean up old blue environment
ssh -i /tmp/blue_green_key.pem -o StrictHostKeyChecking=no ubuntu@$TARGET_HOST "
    cd /opt/app
    
    # Stop blue environment
    echo 'Stopping old blue environment...'
    docker-compose -f docker-compose.blue-green.yml stop app-blue
    docker-compose -f docker-compose.blue-green.yml rm -f app-blue
    
    # Clean up old images
    docker image prune -f
"

# Clean up
rm -f /tmp/blue_green_key.pem
rm -f docker-compose.blue-green.yml

echo "Blue-Green deployment completed successfully!"
echo "Application is now running on green environment"
echo "Access URL: http://$TARGET_HOST:8082"
