package com.devops.microservice.controller;

import com.devops.microservice.dto.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * Health check controller for monitoring
 */
@RestController
@RequestMapping("/api/v1/health")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "Health Check", description = "Health check and monitoring APIs")
public class HealthController {

    @Value("${spring.application.name:user-registration-service}")
    private String applicationName;

    @Value("${app.version:1.0.0}")
    private String applicationVersion;

    @Operation(summary = "Health check", description = "Check if the service is running")
    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> healthCheck() {
        Map<String, Object> healthData = new HashMap<>();
        healthData.put("service", applicationName);
        healthData.put("version", applicationVersion);
        healthData.put("status", "UP");
        healthData.put("timestamp", LocalDateTime.now());
        healthData.put("environment", System.getProperty("spring.profiles.active", "default"));
        
        return ResponseEntity.ok(ApiResponse.success(healthData, "Service is healthy"));
    }

    @Operation(summary = "Readiness probe", description = "Check if the service is ready to handle requests")
    @GetMapping("/ready")
    public ResponseEntity<ApiResponse<Map<String, Object>>> readinessCheck() {
        Map<String, Object> readinessData = new HashMap<>();
        readinessData.put("service", applicationName);
        readinessData.put("ready", true);
        readinessData.put("timestamp", LocalDateTime.now());
        
        return ResponseEntity.ok(ApiResponse.success(readinessData, "Service is ready"));
    }

    @Operation(summary = "Liveness probe", description = "Check if the service is alive")
    @GetMapping("/live")
    public ResponseEntity<ApiResponse<Map<String, Object>>> livenessCheck() {
        Map<String, Object> livenessData = new HashMap<>();
        livenessData.put("service", applicationName);
        livenessData.put("alive", true);
        livenessData.put("timestamp", LocalDateTime.now());
        
        return ResponseEntity.ok(ApiResponse.success(livenessData, "Service is alive"));
    }
}
