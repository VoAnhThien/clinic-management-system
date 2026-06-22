package com.clinic.service;

import com.clinic.dto.clinic.ClinicRequest;
import com.clinic.dto.clinic.ClinicResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import java.util.UUID;

public interface ClinicService {
    Page<ClinicResponse> getAll(Pageable pageable);
    ClinicResponse getById(UUID id);
    ClinicResponse create(ClinicRequest request);
    ClinicResponse update(UUID id, ClinicRequest request);
}