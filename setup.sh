#!/bin/bash

echo "==========================================="
echo "User Registration Service Setup"
echo "==========================================="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running on WSL
if grep -q Microsoft /proc/version; then
    echo -e "${BLUE}Running on Windows Subsystem for Linux${NC}"
    echo
fi

echo -e "${YELLOW}Checking prerequisites...${NC}"
echo

# Check Java
echo -e "${BLUE}[1/3] Checking Java 17 installation...${NC}"
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | head -n1 | cut -d'"' -f2)
    if [[ "$JAVA_VERSION" == *"17"* ]]; then
        echo -e "${GREEN}Java 17 is installed${NC}"
    else
        echo -e "${YELLOW}Java version: $JAVA_VERSION (Java 17 recommended)${NC}"
    fi
else
    echo -e "${RED}Java is not installed${NC}"
    echo -e "${YELLOW}Installing Java 17...${NC}"
    sudo apt update
    sudo apt install -y openjdk-17-jdk
    echo -e "${GREEN}Java 17 installed${NC}"
fi

# Check Maven
echo -e "${BLUE}[2/3] Checking Maven installation...${NC}"
if command -v mvn &> /dev/null; then
    echo -e "${GREEN}Maven is installed${NC}"
else
    echo -e "${RED}Maven is not installed${NC}"
    echo -e "${YELLOW}Installing Maven...${NC}"
    sudo apt update
    sudo apt install -y maven
    echo -e "${GREEN}Maven installed${NC}"
fi

# Check Docker (optional)
echo -e "${BLUE}[3/3] Checking Docker installation...${NC}"
if command -v docker &> /dev/null; then
    echo -e "${GREEN}Docker is installed${NC}"
else
    echo -e "${YELLOW}Docker is not installed (optional)${NC}"
    echo -e "${YELLOW}You can install it later with: sudo apt install docker.io${NC}"
fi

echo
echo -e "${GREEN}Setup Options:${NC}"
echo "1. Quick Start (H2 Database - No MySQL needed)"
echo "2. Docker Development (Full Stack with MySQL)"
echo "3. Test the Application"
echo "4. Exit"
echo

read -p "Choose an option (1-4): " choice

case $choice in
    1)
        echo
        echo -e "${GREEN}Starting application with H2 database...${NC}"
        echo -e "${BLUE}Profile: test${NC}"
        echo -e "${BLUE}Database: H2 (in-memory)${NC}"
        echo
        mvn spring-boot:run -Dspring-boot.run.profiles=test
        ;;
    2)
        echo
        echo -e "${GREEN}Starting with Docker Compose...${NC}"
        if command -v docker-compose &> /dev/null || command -v docker &> /dev/null; then
            docker-compose up -d
            echo
            echo -e "${GREEN}Access points:${NC}"
            echo "- Application: http://localhost:8080"
            echo "- Swagger UI: http://localhost:8080/swagger-ui.html"
            echo "- Health Check: http://localhost:8080/api/v1/health"
        else
            echo -e "${RED}Docker is not installed. Installing...${NC}"
            sudo apt update
            sudo apt install -y docker.io docker-compose
            sudo systemctl start docker
            sudo usermod -aG docker $USER
            echo -e "${YELLOW}Please log out and log back in, then run this script again${NC}"
        fi
        ;;
    3)
        echo
        echo -e "${GREEN}Running tests...${NC}"
        mvn test
        ;;
    4)
        echo
        echo -e "${GREEN}Goodbye!${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid option. Please choose 1-4.${NC}"
        ;;
esac

echo
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}==========================================${NC}"
echo
echo -e "${GREEN}Access Points:${NC}"
echo "- Application: http://localhost:8080"
echo "- Swagger UI: http://localhost:8080/swagger-ui.html"
echo "- Health Check: http://localhost:8080/api/v1/health"
echo
echo -e "${YELLOW}Default Admin Credentials:${NC}"
echo "- Username: admin"
echo "- Password: admin123"
echo
echo -e "${BLUE}Quick Test Commands:${NC}"
echo "curl http://localhost:8080/api/v1/health"
echo "curl -X POST http://localhost:8080/api/v1/auth/register \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"username\":\"testuser\",\"email\":\"test@example.com\",\"password\":\"password123\"}'"
echo
