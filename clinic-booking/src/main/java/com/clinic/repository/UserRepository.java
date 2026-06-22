package com.clinic.repository;

import com.clinic.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserRepository extends JpaRepository<User, UUID> {
    Optional<User> findByPhone(String phone);
    Optional<User> findByNationalId(String nationalId);
    Optional<User> findByEmail(String email);
    boolean existsByPhone(String phone);
    boolean existsByNationalId(String nationalId);
    boolean existsByEmail(String email);
}