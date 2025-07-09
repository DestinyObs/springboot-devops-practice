# Contributing to User Registration Service

Thank you for considering contributing to this project! This document outlines the process for contributing to the User Registration Service.

## Development Environment Setup

1. **Prerequisites**
   - Java 17 or later
   - Maven 3.8+
   - Git
   - Docker (optional, for testing)

2. **Fork and Clone**
   ```bash
   git clone https://github.com/your-username/springboot-devops-practice.git
   cd springboot-devops-practice
   ```

3. **Build and Test**
   ```bash
   mvn clean compile
   mvn test
   ```

## Development Workflow

1. **Create a Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make Your Changes**
   - Follow the existing code style
   - Add tests for new functionality
   - Update documentation as needed

3. **Test Your Changes**
   ```bash
   mvn test
   mvn verify
   ```

4. **Commit Your Changes**
   ```bash
   git add .
   git commit -m "feat: add new feature description"
   ```

5. **Push and Create Pull Request**
   ```bash
   git push origin feature/your-feature-name
   ```

## Code Style Guidelines

- **Java Style**: Follow Google Java Style Guide
- **Naming**: Use descriptive names for classes, methods, and variables
- **Comments**: Add JavaDoc for public methods and classes
- **Formatting**: Use consistent indentation (4 spaces)
- **Lombok**: Use Lombok annotations to reduce boilerplate code

## Commit Message Format

Use semantic commit messages:
- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation changes
- `test:` for test-related changes
- `refactor:` for code refactoring
- `style:` for formatting changes
- `chore:` for maintenance tasks

Example:
```
feat: add password reset functionality
fix: resolve JWT token validation issue
docs: update API documentation
```

## Testing Guidelines

- **Unit Tests**: Test individual components in isolation
- **Integration Tests**: Test component interactions
- **Test Coverage**: Aim for at least 80% coverage
- **Test Naming**: Use descriptive test method names

Example test structure:
```java
@Test
void shouldReturnUserWhenValidCredentialsProvided() {
    // given
    LoginRequest request = new LoginRequest("testuser", "password");
    
    // when
    UserResponse response = authService.login(request);
    
    // then
    assertThat(response.getUsername()).isEqualTo("testuser");
}
```

## Documentation

- Update README.md for new features
- Add API documentation with Swagger annotations
- Include code examples for complex functionality
- Update configuration documentation

## Pull Request Process

1. **Before Submitting**
   - Ensure all tests pass
   - Update documentation
   - Rebase on latest main branch

2. **Pull Request Description**
   - Clear description of changes
   - Link to related issues
   - Include screenshots if applicable

3. **Review Process**
   - PRs require at least one approval
   - Address reviewer feedback
   - Ensure CI/CD pipeline passes

## Issue Reporting

When reporting issues:
- Use the issue templates provided
- Include steps to reproduce
- Provide system information
- Include relevant logs or screenshots

## Questions or Help

- Open an issue for bug reports
- Use discussions for questions
- Check existing issues before creating new ones

Thank you for contributing!
