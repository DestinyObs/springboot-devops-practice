package com.devops.microservice.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import io.swagger.v3.oas.models.servers.Server;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.Arrays;
import java.util.List;

/**
 * OpenAPI (Swagger) configuration
 */
@Configuration
public class OpenApiConfig {

    @Value("${server.port:8080}")
    private String serverPort;

    @Value("${app.swagger.servers:http://localhost:8080}")
    private String swaggerServers;

    @Bean
    public OpenAPI customOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("User Registration Service API")
                        .version("1.0.0")
                        .description("A Spring Boot service for user registration and authentication with JWT")
                        .contact(new Contact()
                                .name("Development Team")
                                .email("dev@example.com")
                                .url("https://github.com/dev-team"))
                        .license(new License()
                                .name("MIT License")
                                .url("https://opensource.org/licenses/MIT")))
                .servers(getServers())
                .addSecurityItem(new SecurityRequirement().addList("bearerAuth"))
                .components(new io.swagger.v3.oas.models.Components()
                        .addSecuritySchemes("bearerAuth", new SecurityScheme()
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .bearerFormat("JWT")
                                .description("JWT Authorization header using Bearer scheme. Example: \"Authorization: Bearer {token}\"")));
    }

    private List<Server> getServers() {
        return Arrays.asList(swaggerServers.split(","))
                .stream()
                .map(String::trim)
                .filter(url -> !url.isEmpty())
                .map(url -> new Server().url(url).description(getServerDescription(url)))
                .toList();
    }

    private String getServerDescription(String url) {
        if (url.contains("localhost") || url.contains("127.0.0.1")) {
            return "Local development server";
        } else if (url.contains("dev") || url.contains("staging")) {
            return "Development/Staging server";
        } else {
            return "Production server";
        }
    }
}
