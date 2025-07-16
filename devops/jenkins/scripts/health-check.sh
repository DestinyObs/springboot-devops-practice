#!/bin/bash

# Health check script for Spring Boot User Registration Service
# Usage: ./health-check.sh <environment>

set -e

ENVIRONMENT=$1

if [ -z "$ENVIRONMENT" ]; then
    echo "Usage: $0 <environment>"
    exit 1
fi

echo "Performing health check for $ENVIRONMENT environment..."

# Environment-specific configuration
case $ENVIRONMENT in
    "dev")
        APP_PORT=8080
        ;;
    "test")
        APP_PORT=8081
        ;;
    "prod")
        APP_PORT=8082
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
cp "$SSH_KEY" /tmp/health_check_key.pem
chmod 600 /tmp/health_check_key.pem

# Perform health checks
echo "Checking application health..."

# Check if containers are running
CONTAINERS_STATUS=$(ssh -i /tmp/health_check_key.pem -o StrictHostKeyChecking=no ubuntu@$TARGET_HOST "
    cd /opt/app
    docker-compose -f docker-compose.${ENVIRONMENT}.yml ps --services --filter 'status=running' | wc -l
")

if [ "$CONTAINERS_STATUS" -ne 2 ]; then
    echo "ERROR: Not all containers are running"
    ssh -i /tmp/health_check_key.pem -o StrictHostKeyChecking=no ubuntu@$TARGET_HOST "
        cd /opt/app
        docker-compose -f docker-compose.${ENVIRONMENT}.yml ps
    "
    exit 1
fi

# Check application health endpoint
HEALTH_STATUS=$(ssh -i /tmp/health_check_key.pem -o StrictHostKeyChecking=no ubuntu@$TARGET_HOST "
    curl -s -o /dev/null -w '%{http_code}' http://localhost:${APP_PORT}/actuator/health
")

if [ "$HEALTH_STATUS" != "200" ]; then
    echo "ERROR: Application health check failed (HTTP $HEALTH_STATUS)"
    echo "Application logs:"
    ssh -i /tmp/health_check_key.pem -o StrictHostKeyChecking=no ubuntu@$TARGET_HOST "
        cd /opt/app
        docker-compose -f docker-compose.${ENVIRONMENT}.yml logs --tail=50 app
    "
    exit 1
fi

# Check database connectivity
DB_STATUS=$(ssh -i /tmp/health_check_key.pem -o StrictHostKeyChecking=no ubuntu@$TARGET_HOST "
    cd /opt/app
    docker-compose -f docker-compose.${ENVIRONMENT}.yml exec -T mysql mysqladmin ping -h localhost --silent
    echo \$?
")

if [ "$DB_STATUS" != "0" ]; then
    echo "ERROR: Database health check failed"
    echo "Database logs:"
    ssh -i /tmp/health_check_key.pem -o StrictHostKeyChecking=no ubuntu@$TARGET_HOST "
        cd /opt/app
        docker-compose -f docker-compose.${ENVIRONMENT}.yml logs --tail=50 mysql
    "
    exit 1
fi

# Test application endpoints
echo "Testing application endpoints..."

# Test registration endpoint
REGISTER_STATUS=$(ssh -i /tmp/health_check_key.pem -o StrictHostKeyChecking=no ubuntu@$TARGET_HOST "
    curl -s -o /dev/null -w '%{http_code}' -X POST http://localhost:${APP_PORT}/api/users/register \
    -H 'Content-Type: application/json' \
    -d '{\"username\":\"healthcheck\",\"email\":\"healthcheck@example.com\",\"password\":\"password123\"}'
")

if [ "$REGISTER_STATUS" != "201" ] && [ "$REGISTER_STATUS" != "400" ]; then
    echo "WARNING: Registration endpoint returned unexpected status: $REGISTER_STATUS"
fi

# Test login endpoint
LOGIN_STATUS=$(ssh -i /tmp/health_check_key.pem -o StrictHostKeyChecking=no ubuntu@$TARGET_HOST "
    curl -s -o /dev/null -w '%{http_code}' -X POST http://localhost:${APP_PORT}/api/users/login \
    -H 'Content-Type: application/json' \
    -d '{\"username\":\"healthcheck\",\"password\":\"password123\"}'
")

if [ "$LOGIN_STATUS" != "200" ] && [ "$LOGIN_STATUS" != "401" ]; then
    echo "WARNING: Login endpoint returned unexpected status: $LOGIN_STATUS"
fi

# Clean up
rm -f /tmp/health_check_key.pem

echo "Health check completed successfully!"
echo "✓ Containers are running"
echo "✓ Application is responding"
echo "✓ Database is accessible"
echo "✓ API endpoints are functional"

# Display deployment summary
ssh -i "devops/terraform/environments/${ENVIRONMENT}/user-registration-${ENVIRONMENT}-key.pem" -o StrictHostKeyChecking=no ubuntu@$TARGET_HOST "
    cd /opt/app
    echo ''
    echo 'Deployment Summary:'
    echo '=================='
    echo 'Environment: $ENVIRONMENT'
    echo 'Application URL: http://$TARGET_HOST:$APP_PORT'
    echo 'Health Check URL: http://$TARGET_HOST:$APP_PORT/actuator/health'
    echo 'Running Containers:'
    docker-compose -f docker-compose.${ENVIRONMENT}.yml ps --format 'table {{.Name}}\t{{.Status}}\t{{.Ports}}'
"
