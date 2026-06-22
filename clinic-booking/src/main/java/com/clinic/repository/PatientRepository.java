package com.clinic.repository;

import com.clinic.entity.Patient;
import com.clinic.enums.RelationType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface PatientRepository extends JpaRepository<Patient, UUID> {
    Optional<Patient> findByUserId(UUID userId);
    // Lấy tất cả hồ sơ do 1 user tạo (bản thân + người thân)
    List<Patient> findByCreatedById(UUID createdById);

    //chi ho so nguoi than
    List<Patient> findByCreatedByIdAndRelationToCreatorNot(UUID createdById, RelationType relation);
}