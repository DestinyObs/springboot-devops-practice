package com.devops.microservice.service;

import com.devops.microservice.dto.request.LoginRequest;
import com.devops.microservice.dto.request.UserRegistrationRequest;
import com.devops.microservice.dto.response.JwtResponse;
import com.devops.microservice.dto.response.UserResponse;

/**
 * Service interface for Authentication operations
 */
public interface AuthService {

    /**
     * Authenticate user and return JWT token
     */
    JwtResponse authenticateUser(LoginRequest loginRequest);

    /**
     * Register a new user
     */
    UserResponse registerUser(UserRegistrationRequest registrationRequest);

    /**
     * Refresh JWT token
     */
    JwtResponse refreshToken(String refreshToken);

    /**
     * Logout user (invalidate token)
     */
    void logout(String token);
}
