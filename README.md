# User Registration Service

A production-ready Spring Boot microservice for user registration and authentication with JWT tokens. This is a complete backend REST API service designed for DevOps practice, CI/CD pipelines, and cloud deployment.

## What This Application Does

This is a **backend-only microservice** that provides:

- **User Registration & Authentication**: Complete user management with secure registration and login
- **JWT Token Authentication**: Stateless authentication using JSON Web Tokens
- **Role-Based Access Control**: Support for USER, ADMIN, and MODERATOR roles
- **Secure Password Handling**: BCrypt password hashing with validation
- **RESTful API Design**: Clean, documented API endpoints following REST conventions
- **Health Monitoring**: Built-in health checks for DevOps monitoring
- **Production Security**: Spring Security configuration with CORS, CSRF protection
- **API Documentation**: Interactive Swagger UI for easy testing and documentation

## Perfect For

- **DevOps Practice**: CI/CD pipelines, containerization, cloud deployment
- **Microservice Architecture**: Backend service for larger applications
- **API Development**: Learning REST API design and security patterns
- **Testing & Monitoring**: Health checks, metrics, and observability
- **Security Implementation**: JWT authentication and authorization examples

## Key Features

- **Zero Frontend**: Pure backend service - test via API tools or Swagger UI
- **Multi-Environment**: Development, testing, and production configurations
- **Docker Ready**: Complete containerization with Docker Compose
- **Database Flexibility**: MySQL for production, H2 for development/testing
- **Comprehensive Testing**: Unit tests, integration tests, and test coverage
- **Security Best Practices**: OWASP guidelines, secure defaults, environment-based secrets

## Table of Contents

- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [API Endpoints](#api-endpoints)
- [Usage Examples](#usage-examples)
- [Configuration](#configuration)
- [Docker Deployment](#docker-deployment)
- [Testing](#testing)
- [Development](#development)
- [Troubleshooting](#troubleshooting)
- [Deployment](#deployment)
- [Contributing](#contributing)

## Quick Start

### Prerequisites
- Java 17+ (will be installed automatically by setup script)
- Maven 3.6+ (will be installed automatically by setup script)
- Docker (optional, for full stack deployment)

### Option 1: Ubuntu/WSL (Recommended)

1. **Clone and navigate to the project**
   ```bash
   git clone <repository-url>
   cd springboot-devops-practice
   ```

2. **Run the setup script**
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

3. **Choose deployment option**
   - Option 1: H2 Database (quickest, no MySQL needed)
   - Option 2: MySQL + Docker
   - Option 3: Full Docker Compose stack

4. **Access the application**
   - API Base URL: `http://localhost:8080`
   - Swagger UI: `http://localhost:8080/swagger-ui.html`
   - Health Check: `http://localhost:8080/api/v1/health`

### Option 2: Windows/PowerShell

1. **Install Prerequisites**
   ```powershell
   # Install Java 17 (if not already installed)
   winget install Microsoft.OpenJDK.17
   
   # Install Maven (if not already installed)
   winget install Apache.Maven
   
   # Verify installations
   java -version
   mvn -version
   ```

2. **Clone and build**
   ```powershell
   git clone <repository-url>
   cd springboot-devops-practice
   mvn clean package -DskipTests
   ```

3. **Run with H2 (easiest)**
   ```powershell
   java -jar target/user-registration-service-*.jar --spring.profiles.active=test
   ```

4. **Run with MySQL (if you have MySQL installed)**
   ```powershell
   # Create database first
   mysql -u root -p -e "CREATE DATABASE user_registration_db;"
   
   # Run application
   java -jar target/user-registration-service-*.jar --spring.profiles.active=dev
   ```

### Option 3: Docker (Any Platform)

```bash
# Quick start with Docker Compose
docker-compose up -d

# Or build and run manually
docker build -t user-registration-service .
docker run -p 8080:8080 -e SPRING_PROFILES_ACTIVE=test user-registration-service
```

### Default Admin Credentials
- Username: `admin`
- Password: `admin123`

## Technologies Used

- **Framework**: Spring Boot 3.2.0
- **Language**: Java 17
- **Database**: MySQL 8.0 / H2 (testing)
- **Security**: Spring Security + JWT
- **Documentation**: Swagger/OpenAPI 3.0
- **Testing**: JUnit 5, Mockito, TestContainers
- **Build Tool**: Maven 3.8+
- **Containerization**: Docker, Docker Compose
- **Monitoring**: Spring Boot Actuator
- **Validation**: Bean Validation (Hibernate Validator)
- **JSON Processing**: Jackson
- **Password Hashing**: BCrypt

## Architecture

```
src/
├── main/
│   ├── java/com/devops/microservice/
│   │   ├── config/           # Configuration classes
│   │   ├── controller/       # REST controllers
│   │   ├── dto/             # Data Transfer Objects
│   │   ├── entity/          # JPA entities
│   │   ├── exception/       # Custom exceptions
│   │   ├── repository/      # Data repositories
│   │   ├── security/        # Security configuration
│   │   └── service/         # Business logic
│   └── resources/
│       ├── application.properties
│       ├── application-dev.properties
│       ├── application-test.properties
│       └── application-prod.properties
└── test/                    # Unit and integration tests
```

## API Endpoints

### Authentication Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/register` | Register new user |
| POST | `/api/v1/auth/login` | User login |
| POST | `/api/v1/auth/refresh` | Refresh JWT token |
| POST | `/api/v1/auth/logout` | User logout |

### User Management Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/v1/users/profile` | Get current user profile | Yes |
| GET | `/api/v1/users/{id}` | Get user by ID | Yes (Admin) |
| GET | `/api/v1/users` | Get all users | Yes (Admin) |
| PUT | `/api/v1/users/{id}` | Update user | Yes (Admin) |
| DELETE | `/api/v1/users/{id}` | Delete user | Yes (Admin) |

### Health Check Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/health` | Health check |
| GET | `/api/v1/health/ready` | Readiness probe |
| GET | `/api/v1/health/live` | Liveness probe |

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | Database connection URL | `jdbc:mysql://localhost:3306/user_registration_db` |
| `DATABASE_USERNAME` | Database username | `root` |
| `DATABASE_PASSWORD` | Database password | `root123` |
| `JWT_SECRET` | JWT secret key | Auto-generated |
| `JWT_EXPIRATION` | JWT expiration time (ms) | `86400000` (24 hours) |

### CORS Configuration

The application supports flexible CORS configuration through environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `CORS_ALLOWED_ORIGINS` | Comma-separated list of allowed origins | `http://localhost:8080,http://127.0.0.1:8080,http://localhost:3000` |
| `CORS_ALLOWED_PATTERNS` | Comma-separated list of origin patterns | `http://*:8080,https://*:8080` |
| `CORS_ALLOW_CREDENTIALS` | Allow credentials in CORS requests | `true` |
| `SWAGGER_SERVERS` | Comma-separated list of Swagger server URLs | `http://localhost:8080` |

**Examples:**
```bash
# For development with any localhost port
export CORS_ALLOWED_ORIGINS="*"
export CORS_ALLOWED_PATTERNS="http://localhost:*,https://localhost:*"

# For production with specific domains
export CORS_ALLOWED_ORIGINS="https://yourdomain.com,https://app.yourdomain.com"

# For cloud deployment with public IP
export CORS_ALLOWED_ORIGINS="http://your-public-ip:8080"
export SWAGGER_SERVERS="http://your-public-ip:8080,http://localhost:8080"
```

For detailed CORS configuration guide, see [CORS_CONFIGURATION.md](CORS_CONFIGURATION.md).

### Application Profiles

- **dev**: Development environment with detailed logging
- **test**: Testing environment with H2 database
- **prod**: Production environment with security optimizations

## Docker Deployment

### Using Docker Compose

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f app

# Stop all services
docker-compose down
```

### Manual Docker Build

```bash
# Build the application
mvn clean package -DskipTests

# Build Docker image
docker build -t user-registration-service .

# Create network
docker network create app-network

# Run MySQL
docker run -d --name mysql \
  --network app-network \
  -e MYSQL_ROOT_PASSWORD=root123 \
  -e MYSQL_DATABASE=user_registration_dev \
  -p 3306:3306 \
  mysql:8.0

# Run your app
docker run -d --name user-app \
  --network app-network \
  -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=dev \
  -e SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/user_registration_dev \
  user-registration-service:latest
```

## Testing

### Run Tests

```bash
# Run all tests
mvn test

# Run tests with coverage
mvn test jacoco:report

# Run integration tests
mvn verify -Dspring.profiles.active=test
```

## Usage Examples

### 1. Register a New User

**Linux/Mac (curl):**
```bash
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "johndoe",
    "email": "john@example.com",
    "password": "securePassword123",
    "firstName": "John",
    "lastName": "Doe"
  }'
```

**Windows (PowerShell):**
```powershell
$body = @{
    username = "johndoe"
    email = "john@example.com"
    password = "securePassword123"
    firstName = "John"
    lastName = "Doe"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/register" -Method Post -Body $body -ContentType "application/json"
```

**Expected Response:**
```json
{
  "id": 1,
  "username": "johndoe",
  "email": "john@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "roles": ["USER"]
}
```

### 2. Login and Get JWT Token

**Linux/Mac (curl):**
```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "johndoe",
    "password": "securePassword123"
  }'
```

**Windows (PowerShell):**
```powershell
$loginBody = @{
    username = "johndoe"
    password = "securePassword123"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
$token = $response.token
```

**Expected Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "type": "Bearer",
  "username": "johndoe",
  "roles": ["USER"]
}
```

### 3. Access Protected Endpoints

**Linux/Mac (curl):**
```bash
# Save token from login response
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Get user profile
curl -X GET "http://localhost:8080/api/v1/users/profile?username=johndoe" \
  -H "Authorization: Bearer $TOKEN"
```

**Windows (PowerShell):**
```powershell
# Using token from login
$headers = @{
    "Authorization" = "Bearer $token"
}

Invoke-RestMethod -Uri "http://localhost:8080/api/v1/users/profile?username=johndoe" -Method Get -Headers $headers
```

### 4. Admin Operations

**Get All Users (Admin only):**
```bash
# Login as admin first
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "admin123"
  }'

# Use admin token to get all users
curl -X GET http://localhost:8080/api/v1/users \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

### 5. Health Check

**Basic Health Check:**
```bash
curl http://localhost:8080/api/v1/health
```

**Response:**
```json
{
  "status": "UP",
  "timestamp": "2024-01-01T12:00:00Z",
  "version": "1.0.0"
}
```

### 6. Using Swagger UI

The easiest way to test the API is through Swagger UI:

1. Start the application
2. Open: `http://localhost:8080/swagger-ui.html`
3. Use the interactive interface to test all endpoints
4. JWT tokens are automatically handled once you login through Swagger

## Development

### Local Development Setup

1. **IDE Setup**
   - Import as Maven project
   - Set Java version to 17
   - Enable annotation processing for Lombok

2. **Database Setup**
   ```bash
   # For MySQL development
   docker run -d --name mysql-dev \
     -e MYSQL_ROOT_PASSWORD=root123 \
     -e MYSQL_DATABASE=user_registration_db \
     -p 3306:3306 mysql:8.0
   ```

3. **Environment Configuration**
   ```bash
   # Create .env file for local development
   echo "DATABASE_URL=jdbc:mysql://localhost:3306/user_registration_db" > .env
   echo "DATABASE_USERNAME=root" >> .env
   echo "DATABASE_PASSWORD=root123" >> .env
   echo "JWT_SECRET=your-secret-key-here" >> .env
   ```

4. **Running in Development Mode**
   ```bash
   mvn spring-boot:run -Dspring-boot.run.profiles=dev
   ```

### Code Structure

```
src/main/java/com/devops/microservice/
├── UserRegistrationServiceApplication.java  # Main application class
├── config/
│   ├── SecurityConfig.java                  # Security configuration
│   ├── SwaggerConfig.java                   # API documentation config
│   └── JwtConfig.java                       # JWT configuration
├── controller/
│   ├── AuthController.java                  # Authentication endpoints
│   ├── UserController.java                  # User management endpoints
│   └── HealthController.java                # Health check endpoints
├── dto/
│   ├── request/                             # Request DTOs
│   │   ├── LoginRequest.java
│   │   ├── RegisterRequest.java
│   │   └── UpdateUserRequest.java
│   └── response/                            # Response DTOs
│       ├── JwtResponse.java
│       ├── UserResponse.java
│       └── HealthResponse.java
├── entity/
│   ├── User.java                            # User entity
│   └── Role.java                            # Role entity
├── exception/
│   ├── GlobalExceptionHandler.java          # Global exception handling
│   ├── UserAlreadyExistsException.java
│   └── InvalidCredentialsException.java
├── repository/
│   ├── UserRepository.java                  # User data access
│   └── RoleRepository.java                  # Role data access
├── security/
│   ├── JwtAuthenticationFilter.java         # JWT filter
│   ├── JwtTokenProvider.java                # JWT token operations
│   └── CustomUserDetailsService.java       # User details service
└── service/
    ├── AuthService.java                     # Authentication logic
    ├── UserService.java                     # User management logic
    └── HealthService.java                   # Health check logic
```

### Adding New Features

1. **Create new endpoint:**
   ```java
   @RestController
   @RequestMapping("/api/v1/your-feature")
   public class YourFeatureController {
       // Controller logic
   }
   ```

2. **Add service layer:**
   ```java
   @Service
   public class YourFeatureService {
       // Business logic
   }
   ```

3. **Write tests:**
   ```java
   @SpringBootTest
   class YourFeatureServiceTest {
       // Test logic
   }
   ```

## Troubleshooting

### Common Issues

#### 1. Port Already in Use
```bash
# Error: Port 8080 is already in use
# Solution: Find and kill the process
netstat -tlnp | grep :8080
kill -9 <PID>

# Or use a different port
java -jar target/user-registration-service-*.jar --server.port=8081
```

#### 2. Database Connection Issues
```bash
# Error: Could not connect to MySQL
# Check MySQL is running
docker ps | grep mysql

# Check connection
mysql -h localhost -u root -p user_registration_db

# Reset database
docker-compose down
docker-compose up -d mysql
```

#### 3. JWT Token Issues
```bash
# Error: Invalid JWT token
# Check token format in request headers
Authorization: Bearer <token>

# Verify token hasn't expired (default 24h)
# Login again to get new token
```

#### 4. H2 Database Issues
```bash
# Error: H2 database locked
# Solution: Use different database file
--spring.datasource.url=jdbc:h2:mem:testdb2
```

### Debugging

1. **Enable Debug Logging**
   ```yaml
   # application-dev.properties
   logging.level.com.devops.microservice=DEBUG
   logging.level.org.springframework.security=DEBUG
   ```

2. **Check Application Status**
   ```bash
   # Health check
   curl http://localhost:8080/api/v1/health
   
   # Application info
   curl http://localhost:8080/actuator/info
   ```

3. **View Logs**
   ```bash
   # Application logs
   tail -f logs/application.log
   
   # Docker logs
   docker logs user-registration-app
   ```

### Performance Tuning

1. **Database Connection Pool**
   ```yaml
   spring:
     datasource:
       hikari:
         maximum-pool-size: 20
         minimum-idle: 5
         connection-timeout: 30000
   ```

2. **JVM Options**
   ```bash
   java -Xmx512m -Xms256m -jar target/user-registration-service-*.jar
   ```
