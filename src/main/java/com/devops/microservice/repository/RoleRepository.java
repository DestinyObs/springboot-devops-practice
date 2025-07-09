package com.devops.microservice.repository;

import com.devops.microservice.entity.Role;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * Repository interface for Role entity
 */
@Repository
public interface RoleRepository extends JpaRepository<Role, Long> {

    /**
     * Find role by name
     */
    Optional<Role> findByName(Role.RoleName name);

    /**
     * Check if role exists by name
     */
    boolean existsByName(Role.RoleName name);
}
