package com.devops.microservice.service;

import com.devops.microservice.entity.Role;
import com.devops.microservice.entity.User;
import com.devops.microservice.repository.RoleRepository;
import com.devops.microservice.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Service to initialize default data on application startup
 */
@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class DataInitializationService implements CommandLineRunner {

    private final RoleRepository roleRepository;
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) throws Exception {
        log.info("Initializing application data...");
        
        createDefaultRoles();
        createDefaultAdminUser();
        
        log.info("Application data initialization completed");
    }

    private void createDefaultRoles() {
        log.info("Creating default roles...");
        
        // Create USER role
        if (!roleRepository.existsByName(Role.RoleName.ROLE_USER)) {
            Role userRole = Role.builder()
                    .name(Role.RoleName.ROLE_USER)
                    .description("Default user role")
                    .build();
            roleRepository.save(userRole);
            log.info("Created role: {}", Role.RoleName.ROLE_USER);
        }
        
        // Create ADMIN role
        if (!roleRepository.existsByName(Role.RoleName.ROLE_ADMIN)) {
            Role adminRole = Role.builder()
                    .name(Role.RoleName.ROLE_ADMIN)
                    .description("Administrator role")
                    .build();
            roleRepository.save(adminRole);
            log.info("Created role: {}", Role.RoleName.ROLE_ADMIN);
        }
        
        // Create MODERATOR role
        if (!roleRepository.existsByName(Role.RoleName.ROLE_MODERATOR)) {
            Role moderatorRole = Role.builder()
                    .name(Role.RoleName.ROLE_MODERATOR)
                    .description("Moderator role")
                    .build();
            roleRepository.save(moderatorRole);
            log.info("Created role: {}", Role.RoleName.ROLE_MODERATOR);
        }
    }

    private void createDefaultAdminUser() {
        log.info("Creating default admin user...");
        
        String adminUsername = "admin";
        String adminEmail = "admin@devops.com";
        String adminPassword = "admin123";
        
        if (!userRepository.existsByUsername(adminUsername)) {
            Role adminRole = roleRepository.findByName(Role.RoleName.ROLE_ADMIN)
                    .orElseThrow(() -> new RuntimeException("Admin role not found"));
            
            Role userRole = roleRepository.findByName(Role.RoleName.ROLE_USER)
                    .orElseThrow(() -> new RuntimeException("User role not found"));
            
            User adminUser = User.builder()
                    .username(adminUsername)
                    .email(adminEmail)
                    .password(passwordEncoder.encode(adminPassword))
                    .firstName("System")
                    .lastName("Administrator")
                    .isActive(true)
                    .isEmailVerified(true)
                    .build();
            
            adminUser.addRole(userRole);
            adminUser.addRole(adminRole);
            
            userRepository.save(adminUser);
            log.info("Created default admin user: {}", adminUsername);
            log.info("Default admin credentials - Username: {}, Password: {}", adminUsername, adminPassword);
        }
    }
}
