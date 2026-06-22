package com.clinic.service;
import com.clinic.dto.patient.*;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import java.util.List;
import java.util.UUID;

public interface PatientService {
    PatientResponse getMyProfile(UUID userId);
    PatientResponse updateMyProfile(UUID userId, UpdatePatientRequest request);
    List<PatientResponse> getMyProfiles(UUID userId);
    PatientResponse addRelative(UUID userId, CreateRelativeRequest request);
    PatientResponse updateRelative(UUID userId, UUID patientId, UpdatePatientRequest request);
    Page<PatientResponse> getAllPatients(Pageable pageable);
    PatientResponse getPatientById(UUID patientId);
}
