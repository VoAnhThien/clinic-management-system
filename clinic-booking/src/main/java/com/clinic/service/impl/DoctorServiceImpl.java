package com.clinic.service.impl;

import com.clinic.dto.doctor.DoctorResponse;
import com.clinic.dto.doctor.SpecializationResponse;
import com.clinic.entity.Doctor;
import com.clinic.entity.Specialization;
import com.clinic.exception.ResourceNotFoundException;
import com.clinic.repository.DoctorRepository;
import com.clinic.repository.SpecializationRepository;
import com.clinic.service.DoctorService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class DoctorServiceImpl implements DoctorService {

    private final DoctorRepository doctorRepository;
    private final SpecializationRepository specializationRepository;

    @Override
    public Page<DoctorResponse> getAll(UUID clinicId, UUID specializationId, Pageable pageable) {
        return doctorRepository.findByFilter(clinicId, specializationId, pageable)
                .map(this::toResponse);
    }

    @Override
    public DoctorResponse getById(UUID id) {
        return toResponse(doctorRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Doctor", id)));
    }

    @Override
    public List<SpecializationResponse> getAllSpecializations() {
        return specializationRepository.findAll()
                .stream().map(this::toSpecResponse).toList();
    }

    private DoctorResponse toResponse(Doctor d) {
        return DoctorResponse.builder()
                .id(d.getId())
                .userId(d.getUser().getId())
                .fullName(d.getFullName())
                .licenseNumber(d.getLicenseNumber())
                .phone(d.getPhone())
                .biography(d.getBiography())
                .experienceYears(d.getExperienceYears())
                .avatarUrl(d.getAvatarUrl())
                .specializations(d.getSpecializations().stream()
                        .map(this::toSpecResponse).toList())
                .build();
    }

    private SpecializationResponse toSpecResponse(Specialization s) {
        return SpecializationResponse.builder()
                .id(s.getId())
                .name(s.getName())
                .description(s.getDescription())
                .build();
    }
}