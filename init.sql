-- Initialize the user registration database
CREATE DATABASE IF NOT EXISTS user_registration_db;
USE user_registration_db;

-- Create app user with necessary permissions
CREATE USER IF NOT EXISTS 'app_user'@'%' IDENTIFIED BY 'app_password';
GRANT ALL PRIVILEGES ON user_registration_db.* TO 'app_user'@'%';
FLUSH PRIVILEGES;

-- Optional: Create tables if needed (Spring Boot will handle this with JPA)
-- This is just for reference or manual setup

-- CREATE TABLE IF NOT EXISTS roles (
--     id BIGINT AUTO_INCREMENT PRIMARY KEY,
--     name VARCHAR(20) NOT NULL UNIQUE,
--     description VARCHAR(100)
-- );

-- CREATE TABLE IF NOT EXISTS users (
--     id BIGINT AUTO_INCREMENT PRIMARY KEY,
--     username VARCHAR(50) NOT NULL UNIQUE,
--     email VARCHAR(100) NOT NULL UNIQUE,
--     password VARCHAR(100) NOT NULL,
--     first_name VARCHAR(50),
--     last_name VARCHAR(50),
--     is_active BOOLEAN DEFAULT TRUE,
--     is_email_verified BOOLEAN DEFAULT FALSE,
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
--     last_login TIMESTAMP NULL
-- );

-- CREATE TABLE IF NOT EXISTS user_roles (
--     user_id BIGINT NOT NULL,
--     role_id BIGINT NOT NULL,
--     PRIMARY KEY (user_id, role_id),
--     FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
--     FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
-- );

-- Insert default roles
-- INSERT IGNORE INTO roles (name, description) VALUES
-- ('ROLE_USER', 'Default user role'),
-- ('ROLE_ADMIN', 'Administrator role'),
-- ('ROLE_MODERATOR', 'Moderator role');
