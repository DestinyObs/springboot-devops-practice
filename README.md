# User Registration Service

A Spring Boot REST API for user registration and authentication with JWT tokens.

## Features

- User registration and login
- JWT authentication
- Role-based access control (USER, ADMIN, MODERATOR)
- MySQL database integration
- Docker support
- Swagger API documentation
- Health check endpoints

## Tech Stack

- Java 17
- Spring Boot 3.2.0
- Spring Security
- Spring Data JPA
- MySQL 8.0
- JWT (jsonwebtoken)
- Docker
- Maven

## Quick Start

### Prerequisites
- Java 17
- Maven 3.6+
- MySQL 8.0 (or use Docker)

### Running the Application

1. Clone the repository
2. Build the project:
   ```bash
   mvn clean package
   ```

3. Run with H2 database (for testing):
   ```bash
   java -jar target/user-registration-service-1.0.0.jar --spring.profiles.active=test
   ```

4. Or run with Docker:
   ```bash
   docker-compose up -d
   ```

### API Documentation

Once the application is running, access Swagger UI at:
`http://localhost:8989/swagger-ui.html`

### Default Users

The application comes with pre-configured users:
- Admin: username=`admin`, password=`admin123`
- User: username=`user`, password=`user123`

## API Endpoints

### Authentication
- `POST /api/v1/auth/register` - Register new user
- `POST /api/v1/auth/login` - User login
- `POST /api/v1/auth/refresh` - Refresh JWT token

### Users
- `GET /api/v1/users/profile` - Get user profile
- `GET /api/v1/users` - List all users (Admin only)
- `PUT /api/v1/users/{id}` - Update user (Admin only)

### Health
- `GET /api/v1/health` - Health check

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `SPRING_PROFILES_ACTIVE` | Active profile (dev/test/prod) | - |
| `DATABASE_URL` | Database URL | `jdbc:mysql://localhost:3306/user_registration_db` |
| `DATABASE_USERNAME` | Database username | `root` |
| `DATABASE_PASSWORD` | Database password | `root123` |
| `JWT_SECRET` | JWT secret key | - |

### Profiles

- `test` - H2 in-memory database
- `dev` - MySQL with development settings
- `prod` - MySQL with production settings

## Docker

### Docker Compose

```bash
# Start application with MySQL
docker-compose up -d

# View logs
docker-compose logs -f app

# Stop services
docker-compose down
```

### Building Docker Image

```bash
docker build -t user-registration-service .
```

## Testing

Run tests:
```bash
mvn test
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License.
