package com.clinic.repository;

import com.clinic.entity.Specialization;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;

public interface SpecializationRepository extends JpaRepository<Specialization, UUID> {
}