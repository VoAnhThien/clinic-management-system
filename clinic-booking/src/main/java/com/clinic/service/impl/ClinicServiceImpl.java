package com.clinic.service.impl;

import com.clinic.dto.clinic.ClinicRequest;
import com.clinic.dto.clinic.ClinicResponse;
import com.clinic.entity.Clinic;
import com.clinic.exception.ResourceNotFoundException;
import com.clinic.repository.ClinicRepository;
import com.clinic.service.ClinicService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ClinicServiceImpl implements ClinicService {

    private final ClinicRepository clinicRepository;

    @Override
    public Page<ClinicResponse> getAll(Pageable pageable) {
        return clinicRepository.findAll(pageable).map(this::toResponse);
    }

    @Override
    public ClinicResponse getById(UUID id) {
        return toResponse(clinicRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Clinic", id)));
    }

    @Override
    public ClinicResponse create(ClinicRequest req) {
        Clinic clinic = Clinic.builder()
                .name(req.getName())
                .address(req.getAddress())
                .phone(req.getPhone())
                .email(req.getEmail())
                .description(req.getDescription())
                .isActive(true)
                .build();
        return toResponse(clinicRepository.save(clinic));
    }

    @Override
    public ClinicResponse update(UUID id, ClinicRequest req) {
        Clinic clinic = clinicRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Clinic", id));
        clinic.setName(req.getName());
        clinic.setAddress(req.getAddress());
        clinic.setPhone(req.getPhone());
        clinic.setEmail(req.getEmail());
        clinic.setDescription(req.getDescription());
        return toResponse(clinicRepository.save(clinic));
    }

    private ClinicResponse toResponse(Clinic c) {
        return ClinicResponse.builder()
                .id(c.getId())
                .name(c.getName())
                .address(c.getAddress())
                .phone(c.getPhone())
                .email(c.getEmail())
                .description(c.getDescription())
                .isActive(c.getIsActive())
                .build();
    }
}