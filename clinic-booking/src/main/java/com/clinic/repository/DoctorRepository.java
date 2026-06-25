package com.clinic.repository;

import com.clinic.entity.Doctor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.UUID;
import java.util.Optional;

public interface DoctorRepository extends JpaRepository<Doctor, UUID> {

    Optional<Doctor> findByUserId(UUID userId);

    @Query("""
        SELECT DISTINCT d FROM Doctor d
        LEFT JOIN d.specializations s
        WHERE (:clinicId IS NULL OR EXISTS (
            SELECT 1 FROM DoctorSchedule ds
            WHERE ds.doctor = d AND ds.clinic.id = :clinicId AND ds.isActive = true
        ))
        AND (:specializationId IS NULL OR s.id = :specializationId)
    """)
    Page<Doctor> findByFilter(
        @Param("clinicId") UUID clinicId,
        @Param("specializationId") UUID specializationId,
        Pageable pageable
    );

    boolean existsByUserId(UUID userId);
}