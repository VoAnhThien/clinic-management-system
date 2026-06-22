package com.clinic.repository;

import com.clinic.entity.Clinic;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;

public interface ClinicRepository extends JpaRepository<Clinic, UUID> {
    // findAll(Pageable) đã có sẵn từ JpaRepository
}