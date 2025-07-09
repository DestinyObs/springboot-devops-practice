package com.devops.microservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.transaction.annotation.EnableTransactionManagement;

/**
 * Main application class for User Registration Service
 */
@SpringBootApplication
@EnableCaching
@EnableTransactionManagement
public class UserRegistrationServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(UserRegistrationServiceApplication.class, args);
    }
}
