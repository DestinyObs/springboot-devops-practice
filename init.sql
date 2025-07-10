-- Initialize the user registration database
CREATE DATABASE IF NOT EXISTS user_registration_db;
USE user_registration_db;

-- Create app user with necessary permissions
CREATE USER IF NOT EXISTS 'app_user'@'%' IDENTIFIED BY 'app_password';
GRANT ALL PRIVILEGES ON user_registration_db.* TO 'app_user'@'%';
FLUSH PRIVILEGES;

-- Optional: Create tables if needed (Spring Boot will handle this with JPA)
-- This is just for reference or manual setup

CREATE TABLE IF NOT EXISTS roles (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(20) NOT NULL UNIQUE,
    description VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(100) NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    is_email_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL
);

CREATE TABLE IF NOT EXISTS user_roles (
    user_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
);

-- Insert default roles
INSERT IGNORE INTO roles (name, description) VALUES
('ROLE_USER', 'Default user role with basic permissions'),
('ROLE_ADMIN', 'Administrator role with full system access'),
('ROLE_MODERATOR', 'Moderator role with content management permissions');

-- Insert sample users for testing and demo purposes
-- Note: In production, passwords should be properly hashed
-- These are demo passwords for testing: password123, admin123, mod123, user123

INSERT IGNORE INTO users (username, email, password, first_name, last_name, is_active, is_email_verified, created_at, last_login) VALUES
-- Admin Users
('admin', 'admin@devops-practice.com', '$2a$10$8.UnVuG9HHgffUDAlk8qfOuVGkqRzgVymGe07xd00DMxs.AQubh4a', 'System', 'Administrator', TRUE, TRUE, '2025-01-01 08:00:00', '2025-07-10 09:00:00'),
('superadmin', 'superadmin@devops-practice.com', '$2a$10$8.UnVuG9HHgffUDAlk8qfOuVGkqRzgVymGe07xd00DMxs.AQubh4a', 'Super', 'Admin', TRUE, TRUE, '2025-01-01 08:15:00', '2025-07-10 08:30:00'),

-- Moderator Users  
('moderator1', 'mod1@devops-practice.com', '$2a$10$DowJoayNM..PhqIPgN.iOepeL7MzH1IqT9FVgvNMD5k2LtEF5P8M2', 'Alex', 'Moderator', TRUE, TRUE, '2025-01-15 10:00:00', '2025-07-09 16:45:00'),
('contentmod', 'content.mod@devops-practice.com', '$2a$10$DowJoayNM..PhqIPgN.iOepeL7MzH1IqT9FVgvNMD5k2LtEF5P8M2', 'Sarah', 'Williams', TRUE, TRUE, '2025-02-01 09:30:00', '2025-07-09 14:20:00'),

-- Regular Users - Active
('john_doe', 'john.doe@example.com', '$2a$10$YhuwdEOLpZ9HzGzKOFCo5.wCQDqJDANHLqggMO6xXaZmEYNiHg.yC', 'John', 'Doe', TRUE, TRUE, '2025-02-15 14:22:00', '2025-07-10 07:15:00'),
('jane_smith', 'jane.smith@example.com', '$2a$10$YhuwdEOLpZ9HzGzKOFCo5.wCQDqJDANHLqggMO6xXaZmEYNiHg.yC', 'Jane', 'Smith', TRUE, TRUE, '2025-02-20 11:30:00', '2025-07-09 18:45:00'),
('mike_johnson', 'mike.johnson@example.com', '$2a$10$YhuwdEOLpZ9HzGzKOFCo5.wCQDqJDANHLqggMO6xXaZmEYNiHg.yC', 'Michael', 'Johnson', TRUE, TRUE, '2025-03-01 16:45:00', '2025-07-09 12:30:00'),
('emily_davis', 'emily.davis@example.com', '$2a$10$YhuwdEOLpZ9HzGzKOFCo5.wCQDqJDANHLqggMO6xXaZmEYNiHg.yC', 'Emily', 'Davis', TRUE, TRUE, '2025-03-10 13:20:00', '2025-07-08 20:15:00'),
('david_wilson', 'david.wilson@example.com', '$2a$10$YhuwdEOLpZ9HzGzKOFCo5.wCQDqJDANHLqggMO6xXaZmEYNiHg.yC', 'David', 'Wilson', TRUE, TRUE, '2025-03-15 09:10:00', '2025-07-09 08:45:00'),
('lisa_brown', 'lisa.brown@example.com', '$2a$10$YhuwdEOLpZ9HzGzKOFCo5.wCQDqJDANHLqggMO6xXaZmEYNiHg.yC', 'Lisa', 'Brown', TRUE, TRUE, '2025-04-01 12:30:00', '2025-07-09 15:20:00'),
('robert_taylor', 'robert.taylor@example.com', '$2a$10$YhuwdEOLpZ9HzGzKOFCo5.wCQDqJDANHLqggMO6xXaZmEYNiHg.yC', 'Robert', 'Taylor', TRUE, TRUE, '2025-04-10 10:15:00', '2025-07-08 19:30:00'),
('jennifer_clark', 'jennifer.clark@example.com', '$2a$10$YhuwdEOLpZ9HzGzKOFCo5.wCQDqJDANHLqggMO6xXaZmEYNiHg.yC', 'Jennifer', 'Clark', TRUE, FALSE, '2025-04-20 14:45:00', '2025-07-09 11:10:00'),

-- Regular Users - Some inactive for testing
('inactive_user', 'inactive@example.com', '$2a$10$YhuwdEOLpZ9HzGzKOFCo5.wCQDqJDANHLqggMO6xXaZmEYNiHg.yC', 'Inactive', 'User', FALSE, FALSE, '2025-03-05 08:30:00', '2025-06-15 14:20:00'),
('pending_verification', 'pending@example.com', '$2a$10$YhuwdEOLpZ9HzGzKOFCo5.wCQDqJDANHLqggMO6xXaZmEYNiHg.yC', 'Pending', 'Verification', TRUE, FALSE, '2025-07-09 16:30:00', NULL),

-- Test Users for Development
('testuser', 'test@example.com', '$2a$10$YhuwdEOLpZ9HzGzKOFCo5.wCQDqJDANHLqggMO6xXaZmEYNiHg.yC', 'Test', 'User', TRUE, TRUE, '2025-07-10 08:00:00', '2025-07-10 09:44:33'),
('demo_user', 'demo@devops-practice.com', '$2a$10$YhuwdEOLpZ9HzGzKOFCo5.wCQDqJDANHLqggMO6xXaZmEYNiHg.yC', 'Demo', 'User', TRUE, TRUE, '2025-07-01 12:00:00', '2025-07-09 17:30:00');

-- Assign roles to users
INSERT IGNORE INTO user_roles (user_id, role_id) VALUES
-- Admin users (both ADMIN and USER roles)
(1, 2), (1, 1),  -- admin: ROLE_ADMIN + ROLE_USER
(2, 2), (2, 1),  -- superadmin: ROLE_ADMIN + ROLE_USER

-- Moderator users (both MODERATOR and USER roles)
(3, 3), (3, 1),  -- moderator1: ROLE_MODERATOR + ROLE_USER  
(4, 3), (4, 1),  -- contentmod: ROLE_MODERATOR + ROLE_USER

-- Regular users (USER role only)
(5, 1),   -- john_doe: ROLE_USER
(6, 1),   -- jane_smith: ROLE_USER
(7, 1),   -- mike_johnson: ROLE_USER
(8, 1),   -- emily_davis: ROLE_USER
(9, 1),   -- david_wilson: ROLE_USER
(10, 1),  -- lisa_brown: ROLE_USER
(11, 1),  -- robert_taylor: ROLE_USER
(12, 1),  -- jennifer_clark: ROLE_USER
(13, 1),  -- inactive_user: ROLE_USER
(14, 1),  -- pending_verification: ROLE_USER
(15, 1),  -- testuser: ROLE_USER
(16, 1);  -- demo_user: ROLE_USER

-- Display initialization summary
SELECT 'Database initialization completed!' as status;
SELECT 'Users created:', COUNT(*) as total_users FROM users;
SELECT 'Roles created:', COUNT(*) as total_roles FROM roles;
SELECT 'Role assignments:', COUNT(*) as total_assignments FROM user_roles;
