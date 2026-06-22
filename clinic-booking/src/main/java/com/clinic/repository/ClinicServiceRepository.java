package com.clinic.repository;

import com.clinic.entity.ClinicService;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;

public interface ClinicServiceRepository extends JpaRepository<ClinicService, UUID> {
}