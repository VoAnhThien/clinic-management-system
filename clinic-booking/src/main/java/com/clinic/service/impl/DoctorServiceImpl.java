package com.clinic.service.impl;

import com.clinic.dto.doctor.CreateDoctorRequest;
import com.clinic.dto.doctor.DoctorResponse;
import com.clinic.dto.doctor.SpecializationResponse;
import com.clinic.entity.Doctor;
import com.clinic.entity.Specialization;
import com.clinic.entity.User;
import com.clinic.enums.UserRole;
import com.clinic.exception.ResourceNotFoundException;
import com.clinic.repository.DoctorRepository;
import com.clinic.repository.SpecializationRepository;
import com.clinic.repository.UserRepository;
import com.clinic.service.DoctorService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collections;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class DoctorServiceImpl implements DoctorService {

    private final DoctorRepository doctorRepository;
    private final SpecializationRepository specializationRepository;
    private final UserRepository userRepository;

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

    @Override
    @Transactional
    public DoctorResponse create(CreateDoctorRequest request) {
        // 1. Kiểm tra user tồn tại và có role DOCTOR
        User user = userRepository.findById(request.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("User", request.getUserId()));

        if (user.getRole() != UserRole.DOCTOR) {
            throw new IllegalArgumentException("User không có role DOCTOR");
        }

        // 2. Kiểm tra user chưa được gắn với doctor nào
        if (doctorRepository.existsByUserId(user.getId())) {
            throw new IllegalArgumentException("User này đã được gắn với một bác sĩ khác");
        }

        // 3. Lấy danh sách specializations nếu có
        Set<Specialization> specializations = Collections.emptySet();
        if (request.getSpecializationIds() != null && !request.getSpecializationIds().isEmpty()) {
            specializations = specializationRepository.findByIdIn(request.getSpecializationIds());
        }

        // 4. Tạo Doctor
        Doctor doctor = Doctor.builder()
                .user(user)
                .fullName(request.getFullName())
                .licenseNumber(request.getLicenseNumber())
                .phone(request.getPhone())
                .biography(request.getBiography())
                .experienceYears(request.getExperienceYears() != null ? request.getExperienceYears() : 0)
                .avatarUrl(request.getAvatarUrl())
                .specializations(new java.util.HashSet<>(specializations))
                .build();

        return toResponse(doctorRepository.save(doctor));
    }

    @Override
    public List<DoctorResponse> getUpcomingDoctors() {
        // TODO: implement logic lấy bác sĩ có lịch sắp tới
        return doctorRepository.findAll().stream().map(this::toResponse).toList();
    }

    @Override
    public List<DoctorResponse> getFeaturedDoctors() {
        // TODO: implement logic lấy bác sĩ nổi bật
        return doctorRepository.findAll().stream().map(this::toResponse).toList();
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

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