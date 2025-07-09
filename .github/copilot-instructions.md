# Project Guidelines for User Registration Service

## Project Context
This is a Spring Boot service for user registration and authentication with JWT tokens.

## Architecture Guidelines
- Follow layered architecture: Controller → Service → Repository
- Use DTO pattern for API contracts
- Implement global exception handling
- Apply security best practices with Spring Security
- Use validation with Bean Validation annotations
- Follow RESTful API conventions

## Code Style
- Use Lombok to reduce boilerplate code
- Apply proper logging with SLF4J
- Use meaningful variable names
- Add JavaDoc comments
- Follow Spring Boot conventions

## Testing
- Write unit tests for all service methods
- Use Mockito for mocking dependencies
- Create integration tests for controllers
- Use TestContainers for database testing
- Maintain high test coverage

## Security
- Never hardcode secrets or passwords
- Use environment variables for sensitive data
- Implement proper JWT token handling
- Follow OWASP security guidelines
- Use BCrypt for password hashing

## Database
- Use JPA/Hibernate for ORM
- Implement proper relationships between entities
- Apply indexing for performance
- Use connection pooling

## API Design
- Use OpenAPI/Swagger for documentation
- Implement proper HTTP status codes
- Use consistent response formats
- Apply pagination for list endpoints
- Implement proper error handling

## Dependencies
- Keep dependencies up to date
- Use Spring Boot starters when available
- Minimize external dependencies
- Use managed versions from Spring Boot BOM

## Monitoring
- Implement Actuator endpoints
- Use Prometheus metrics
- Add custom metrics for business logic
- Use structured logging
