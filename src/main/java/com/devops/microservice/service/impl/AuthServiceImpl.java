package com.devops.microservice.service.impl;

import com.devops.microservice.dto.request.LoginRequest;
import com.devops.microservice.dto.request.UserRegistrationRequest;
import com.devops.microservice.dto.response.JwtResponse;
import com.devops.microservice.dto.response.UserResponse;
import com.devops.microservice.security.jwt.JwtUtils;
import com.devops.microservice.security.service.UserDetailsImpl;
import com.devops.microservice.service.AuthService;
import com.devops.microservice.service.UserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Set;
import java.util.stream.Collectors;

/**
 * Service implementation for Authentication operations
 */
@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class AuthServiceImpl implements AuthService {

    private final AuthenticationManager authenticationManager;
    private final JwtUtils jwtUtils;
    private final UserService userService;

    @Override
    public JwtResponse authenticateUser(LoginRequest loginRequest) {
        log.info("Authenticating user: {}", loginRequest.getUsername());

        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        loginRequest.getUsername(), 
                        loginRequest.getPassword()
                )
        );

        SecurityContextHolder.getContext().setAuthentication(authentication);
        
        String jwt = jwtUtils.generateJwtToken(authentication);
        String refreshToken = jwtUtils.generateRefreshToken(loginRequest.getUsername());

        UserDetailsImpl userDetails = (UserDetailsImpl) authentication.getPrincipal();
        Set<String> roles = userDetails.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .collect(Collectors.toSet());

        // Update last login
        userService.updateLastLogin(userDetails.getUsername());

        log.info("User authenticated successfully: {}", loginRequest.getUsername());

        return JwtResponse.builder()
                .token(jwt)
                .refreshToken(refreshToken)
                .type("Bearer")
                .id(userDetails.getId())
                .username(userDetails.getUsername())
                .email(userDetails.getEmail())
                .roles(roles)
                .expiresIn(jwtUtils.getJwtExpirationInSeconds())
                .build();
    }

    @Override
    public UserResponse registerUser(UserRegistrationRequest registrationRequest) {
        log.info("Registering new user: {}", registrationRequest.getUsername());
        return userService.registerUser(registrationRequest);
    }

    @Override
    public JwtResponse refreshToken(String refreshToken) {
        log.info("Refreshing token");

        if (!jwtUtils.validateJwtToken(refreshToken)) {
            throw new RuntimeException("Invalid refresh token");
        }

        if (jwtUtils.isTokenExpired(refreshToken)) {
            throw new RuntimeException("Refresh token has expired");
        }

        String username = jwtUtils.getUsernameFromJwtToken(refreshToken);
        String newJwtToken = jwtUtils.generateTokenFromUsername(username);
        String newRefreshToken = jwtUtils.generateRefreshToken(username);

        UserResponse userResponse = userService.getUserByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        log.info("Token refreshed successfully for user: {}", username);

        return JwtResponse.builder()
                .token(newJwtToken)
                .refreshToken(newRefreshToken)
                .type("Bearer")
                .id(userResponse.getId())
                .username(userResponse.getUsername())
                .email(userResponse.getEmail())
                .roles(userResponse.getRoles())
                .expiresIn(jwtUtils.getJwtExpirationInSeconds())
                .build();
    }

    @Override
    public void logout(String token) {
        log.info("Logging out user");
        // In a real application, you would typically:
        // 1. Add the token to a blacklist
        // 2. Store it in Redis with expiration time
        // 3. Or use a token revocation mechanism
        SecurityContextHolder.clearContext();
        log.info("User logged out successfully");
    }
}
