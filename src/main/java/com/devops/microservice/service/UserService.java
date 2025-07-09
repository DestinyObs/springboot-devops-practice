package com.devops.microservice.service;

import com.devops.microservice.dto.request.UserRegistrationRequest;
import com.devops.microservice.dto.response.UserResponse;
import com.devops.microservice.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.Optional;

/**
 * Service interface for User operations
 */
public interface UserService {

    /**
     * Register a new user
     */
    UserResponse registerUser(UserRegistrationRequest request);

    /**
     * Get user by ID
     */
    Optional<UserResponse> getUserById(Long id);

    /**
     * Get user by username
     */
    Optional<UserResponse> getUserByUsername(String username);

    /**
     * Get user by email
     */
    Optional<UserResponse> getUserByEmail(String email);

    /**
     * Get all users with pagination
     */
    Page<UserResponse> getAllUsers(Pageable pageable);

    /**
     * Update user
     */
    UserResponse updateUser(Long id, UserRegistrationRequest request);

    /**
     * Delete user
     */
    void deleteUser(Long id);

    /**
     * Activate user
     */
    void activateUser(Long id);

    /**
     * Deactivate user
     */
    void deactivateUser(Long id);

    /**
     * Verify user email
     */
    void verifyUserEmail(Long id);

    /**
     * Check if username exists
     */
    boolean existsByUsername(String username);

    /**
     * Check if email exists
     */
    boolean existsByEmail(String email);

    /**
     * Update user last login
     */
    void updateLastLogin(String username);

    /**
     * Convert User entity to UserResponse DTO
     */
    UserResponse convertToUserResponse(User user);
}
