package com.clinic.service;

import com.clinic.dto.doctor.CreateDoctorRequest;
import com.clinic.dto.doctor.DoctorResponse;
import com.clinic.dto.doctor.SpecializationResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import java.util.List;
import java.util.UUID;

public interface DoctorService {
    Page<DoctorResponse> getAll(UUID clinicId, UUID specializationId, Pageable pageable);
    DoctorResponse getById(UUID id);
    List<SpecializationResponse> getAllSpecializations();
    DoctorResponse create(CreateDoctorRequest request);

    List<DoctorResponse> getUpcomingDoctors();
    List<DoctorResponse> getFeaturedDoctors();
    DoctorResponse getByUserId(UUID userId);
}