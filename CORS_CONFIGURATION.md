# CORS Configuration Guide

## Overview

The User Registration Service now supports flexible CORS (Cross-Origin Resource Sharing) configuration that can be easily adapted to different deployment environments without code changes.

## Configuration Properties

The application uses the following environment variables and properties for CORS configuration:

### Basic CORS Properties

| Property | Environment Variable | Default | Description |
|----------|---------------------|---------|-------------|
| `app.cors.allowed-origins` | `CORS_ALLOWED_ORIGINS` | `*` | Comma-separated list of allowed origins |
| `app.cors.allowed-origin-patterns` | `CORS_ALLOWED_PATTERNS` | (empty) | Comma-separated list of origin patterns |
| `app.cors.allowed-methods` | `CORS_ALLOWED_METHODS` | `GET,POST,PUT,DELETE,OPTIONS,HEAD` | Allowed HTTP methods |
| `app.cors.allowed-headers` | `CORS_ALLOWED_HEADERS` | `*` | Allowed headers |
| `app.cors.allow-credentials` | `CORS_ALLOW_CREDENTIALS` | `true` | Whether to allow credentials |
| `app.cors.max-age` | `CORS_MAX_AGE` | `3600` | Cache duration for preflight requests |

### Swagger Configuration

| Property | Environment Variable | Default | Description |
|----------|---------------------|---------|-------------|
| `app.swagger.servers` | `SWAGGER_SERVERS` | `http://localhost:8080` | Comma-separated list of server URLs for Swagger UI |

## Environment-Specific Configurations

### Development Environment

```properties
# Allow all origins (permissive for development)
app.cors.allowed-origins=*
app.cors.allowed-origin-patterns=http://localhost:*,https://localhost:*,http://127.0.0.1:*
app.cors.allowed-methods=GET,POST,PUT,DELETE,OPTIONS,HEAD,PATCH
app.cors.allowed-headers=*
app.cors.allow-credentials=true
app.cors.max-age=3600

# Swagger servers for development
app.swagger.servers=http://localhost:8080,http://127.0.0.1:8080
```

### Production Environment

```properties
# Restrictive CORS for production
app.cors.allowed-origins=https://yourdomain.com,https://app.yourdomain.com
app.cors.allowed-origin-patterns=
app.cors.allowed-methods=GET,POST,PUT,DELETE,OPTIONS,HEAD
app.cors.allowed-headers=Content-Type,Authorization,X-Requested-With,Accept,Origin,Access-Control-Request-Method,Access-Control-Request-Headers
app.cors.allow-credentials=true
app.cors.max-age=1800

# Swagger servers for production
app.swagger.servers=https://api.yourdomain.com
```

## Configuration Examples

### Example 1: Local Development

```bash
# Allow all localhost variants
export CORS_ALLOWED_ORIGINS="http://localhost:8080,http://localhost:3000,http://127.0.0.1:8080"
export CORS_ALLOWED_PATTERNS="http://localhost:*,https://localhost:*"
export SWAGGER_SERVERS="http://localhost:8080,http://127.0.0.1:8080"
```

### Example 2: Docker Environment

```yaml
environment:
  CORS_ALLOWED_ORIGINS: "http://localhost:8080,http://127.0.0.1:8080,http://host.docker.internal:8080"
  CORS_ALLOWED_PATTERNS: "http://*:8080,https://*:8080"
  CORS_ALLOW_CREDENTIALS: "true"
  SWAGGER_SERVERS: "http://localhost:8080,http://127.0.0.1:8080"
```

### Example 3: AWS/Cloud Deployment

```bash
# For a specific public IP and domain
export CORS_ALLOWED_ORIGINS="https://yourdomain.com,https://api.yourdomain.com"
export CORS_ALLOWED_PATTERNS="https://*.yourdomain.com"
export SWAGGER_SERVERS="https://api.yourdomain.com,http://44.201.212.132:8080"
```

### Example 4: Development with External Testing

```bash
# Allow specific external IPs for testing
export CORS_ALLOWED_ORIGINS="http://localhost:8080,http://44.201.212.132:8080"
export CORS_ALLOWED_PATTERNS="http://*:8080,https://*:8080"
export SWAGGER_SERVERS="http://localhost:8080,http://44.201.212.132:8080"
```

## Security Best Practices

### Development
- Use permissive CORS settings (`*` for origins) for ease of development
- Include `localhost` and `127.0.0.1` variants
- Allow all common development ports

### Production
- **Never** use `*` for allowed origins in production
- Specify exact domains and subdomains
- Use HTTPS URLs whenever possible
- Limit allowed headers to only what's necessary
- Set shorter cache times for preflight requests

### Staging/Testing
- Use a middle-ground approach
- Allow specific test domains and IPs
- Include your CI/CD server IPs if needed

## Testing CORS Configuration

### 1. Check CORS Headers

```bash
# Test preflight request
curl -H "Origin: http://localhost:3000" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: Content-Type,Authorization" \
     -X OPTIONS \
     http://localhost:8080/api/v1/auth/login

# Test actual request
curl -H "Origin: http://localhost:3000" \
     -H "Content-Type: application/json" \
     -X POST \
     http://localhost:8080/api/v1/auth/login \
     -d '{"username":"admin","password":"admin123"}'
```

### 2. Browser Developer Tools

1. Open browser developer tools (F12)
2. Go to Network tab
3. Make a request from a different origin
4. Check for CORS-related headers in the response:
   - `Access-Control-Allow-Origin`
   - `Access-Control-Allow-Methods`
   - `Access-Control-Allow-Headers`
   - `Access-Control-Allow-Credentials`

### 3. Swagger UI Testing

Navigate to Swagger UI from different origins and verify:
- Swagger UI loads correctly
- API calls work from the Swagger interface
- No CORS errors in browser console

## Troubleshooting

### Common Issues

1. **CORS Error: "Access to fetch blocked by CORS policy"**
   - Check if the requesting origin is in `allowed-origins` or matches `allowed-origin-patterns`
   - Verify the request method is in `allowed-methods`

2. **Swagger UI not working from external IP**
   - Add the external IP to `app.swagger.servers`
   - Ensure the IP is in `allowed-origins`

3. **Credentials not being sent**
   - Set `app.cors.allow-credentials=true`
   - Ensure the client is sending credentials (cookies, authorization headers)

4. **Preflight requests failing**
   - Check that OPTIONS method is allowed
   - Verify `allowed-headers` includes the headers being requested

### Debug Mode

Enable CORS debugging by adding this to your `application.properties`:

```properties
logging.level.org.springframework.web.cors=DEBUG
logging.level.org.springframework.security=DEBUG
```

## Profile-Specific Overrides

You can override CORS settings for specific Spring profiles:

```bash
# For development profile
java -jar app.jar --spring.profiles.active=dev --app.cors.allowed-origins="*"

# For production profile
java -jar app.jar --spring.profiles.active=prod --app.cors.allowed-origins="https://yourdomain.com"
```

## Environment Variables in Different Deployment Scenarios

### Docker Compose
```yaml
environment:
  - CORS_ALLOWED_ORIGINS=http://localhost:8080,http://127.0.0.1:8080
```

### Kubernetes
```yaml
env:
- name: CORS_ALLOWED_ORIGINS
  value: "https://app.yourdomain.com,https://admin.yourdomain.com"
```

### AWS ECS/Fargate
```json
"environment": [
  {
    "name": "CORS_ALLOWED_ORIGINS",
    "value": "https://yourdomain.com"
  }
]
```

### Systemd Service
```bash
# In your .service file
Environment=CORS_ALLOWED_ORIGINS="https://yourdomain.com"
Environment=CORS_ALLOW_CREDENTIALS="true"
```

This flexible configuration system ensures that your application can be deployed in any environment without code changes, while maintaining security best practices for each deployment scenario.
