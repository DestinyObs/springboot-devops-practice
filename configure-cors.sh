#!/bin/bash

# CORS Configuration Helper Script
# This script helps you set up CORS configuration for different deployment scenarios

echo "=============================================="
echo "CORS Configuration Helper"
echo "=============================================="
echo ""

echo "Choose your deployment scenario:"
echo "1. Local Development (permissive CORS)"
echo "2. Docker Development"
echo "3. Cloud/Public IP Deployment"
echo "4. Production Deployment"
echo "5. Custom Configuration"
echo ""

read -p "Enter your choice (1-5): " choice

case $choice in
    1)
        echo ""
        echo "Setting up Local Development configuration..."
        echo ""
        echo "Add these to your environment or application-dev.properties:"
        echo ""
        echo "CORS_ALLOWED_ORIGINS=*"
        echo "CORS_ALLOWED_PATTERNS=http://localhost:*,https://localhost:*,http://127.0.0.1:*"
        echo "CORS_ALLOW_CREDENTIALS=true"
        echo "SWAGGER_SERVERS=http://localhost:8080,http://127.0.0.1:8080"
        echo ""
        echo "Or run with:"
        echo "export CORS_ALLOWED_ORIGINS=\"*\""
        echo "export CORS_ALLOWED_PATTERNS=\"http://localhost:*,https://localhost:*\""
        echo "java -jar target/user-registration-service-1.0.0.jar"
        ;;
    2)
        echo ""
        echo "Setting up Docker Development configuration..."
        echo ""
        echo "Your docker-compose.yml should include:"
        echo ""
        echo "environment:"
        echo "  CORS_ALLOWED_ORIGINS: \"http://localhost:8080,http://127.0.0.1:8080,http://host.docker.internal:8080\""
        echo "  CORS_ALLOWED_PATTERNS: \"http://*:8080,https://*:8080\""
        echo "  CORS_ALLOW_CREDENTIALS: \"true\""
        echo "  SWAGGER_SERVERS: \"http://localhost:8080,http://127.0.0.1:8080\""
        ;;
    3)
        echo ""
        read -p "Enter your public IP address: " public_ip
        echo ""
        echo "Setting up Cloud/Public IP configuration for: $public_ip"
        echo ""
        echo "Add these environment variables:"
        echo ""
        echo "export CORS_ALLOWED_ORIGINS=\"http://localhost:8080,http://$public_ip:8080\""
        echo "export CORS_ALLOWED_PATTERNS=\"http://*:8080,https://*:8080\""
        echo "export CORS_ALLOW_CREDENTIALS=\"true\""
        echo "export SWAGGER_SERVERS=\"http://localhost:8080,http://$public_ip:8080\""
        echo ""
        echo "For Docker, add to docker-compose.yml:"
        echo ""
        echo "environment:"
        echo "  CORS_ALLOWED_ORIGINS: \"http://localhost:8080,http://$public_ip:8080\""
        echo "  SWAGGER_SERVERS: \"http://localhost:8080,http://$public_ip:8080\""
        ;;
    4)
        echo ""
        read -p "Enter your production domain (e.g., yourdomain.com): " domain
        echo ""
        echo "Setting up Production configuration for: $domain"
        echo ""
        echo "Add these environment variables:"
        echo ""
        echo "export CORS_ALLOWED_ORIGINS=\"https://$domain,https://app.$domain,https://api.$domain\""
        echo "export CORS_ALLOWED_PATTERNS=\"https://*.$domain\""
        echo "export CORS_ALLOW_CREDENTIALS=\"true\""
        echo "export SWAGGER_SERVERS=\"https://api.$domain\""
        echo ""
        echo "⚠️  SECURITY NOTE: Never use '*' for allowed origins in production!"
        ;;
    5)
        echo ""
        echo "Custom Configuration Builder"
        echo ""
        read -p "Enter allowed origins (comma-separated): " origins
        read -p "Enter allowed patterns (comma-separated, optional): " patterns
        read -p "Allow credentials (true/false): " credentials
        read -p "Enter Swagger server URLs (comma-separated): " servers
        echo ""
        echo "Your custom configuration:"
        echo ""
        echo "export CORS_ALLOWED_ORIGINS=\"$origins\""
        if [ ! -z "$patterns" ]; then
            echo "export CORS_ALLOWED_PATTERNS=\"$patterns\""
        fi
        echo "export CORS_ALLOW_CREDENTIALS=\"$credentials\""
        echo "export SWAGGER_SERVERS=\"$servers\""
        ;;
    *)
        echo "Invalid choice. Please run the script again and choose 1-5."
        exit 1
        ;;
esac

echo ""
echo "=============================================="
echo "Configuration complete!"
echo ""
echo "💡 Tips:"
echo "- For development, use permissive settings (*)"
echo "- For production, specify exact domains"
echo "- Always use HTTPS in production"
echo "- Test your configuration with browser dev tools"
echo ""
echo "📖 For more details, see CORS_CONFIGURATION.md"
echo "=============================================="
