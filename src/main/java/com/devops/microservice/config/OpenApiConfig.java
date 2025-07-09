package com.devops.microservice.config;

import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.info.Contact;
import io.swagger.v3.oas.annotations.info.Info;
import io.swagger.v3.oas.annotations.info.License;
import io.swagger.v3.oas.annotations.security.SecurityScheme;
import io.swagger.v3.oas.annotations.servers.Server;
import org.springframework.context.annotation.Configuration;

/**
 * OpenAPI (Swagger) configuration
 */
@Configuration
@OpenAPIDefinition(
        info = @Info(
                title = "User Registration Service API",
                version = "1.0.0",
                description = "A Spring Boot service for user registration and authentication with JWT",
                contact = @Contact(
                        name = "Development Team",
                        email = "dev@example.com",
                        url = "https://github.com/dev-team"
                ),
                license = @License(
                        name = "MIT License",
                        url = "https://opensource.org/licenses/MIT"
                )
        ),
        servers = {
                @Server(url = "http://localhost:8080", description = "Development server"),
                @Server(url = "https://api.example.com", description = "Production server")
        }
)
@SecurityScheme(
        name = "bearerAuth",
        type = SecuritySchemeType.HTTP,
        scheme = "bearer",
        bearerFormat = "JWT",
        description = "JWT Authorization header using Bearer scheme. Example: \"Authorization: Bearer {token}\""
)
public class OpenApiConfig {
}
