package com.clinic.controller;

import com.clinic.dto.doctor.CreateDoctorRequest;
import com.clinic.dto.doctor.DoctorResponse;
import com.clinic.dto.doctor.SpecializationResponse;
import com.clinic.service.DoctorService;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/doctors")
@RequiredArgsConstructor
@Tag(name = "Doctor", description = "Thông tin bác sĩ và chuyên khoa")
public class DoctorController {

    private final DoctorService doctorService;

    @GetMapping
    public ResponseEntity<Page<DoctorResponse>> getAll(
            @RequestParam(required = false) UUID clinicId,
            @RequestParam(required = false) UUID specializationId,
            @PageableDefault(size = 20, sort = "fullName",
                             direction = Sort.Direction.ASC) Pageable pageable) {
        return ResponseEntity.ok(doctorService.getAll(clinicId, specializationId, pageable));
    }

    @GetMapping("/{id}")
    public ResponseEntity<DoctorResponse> getById(@PathVariable UUID id) {
        return ResponseEntity.ok(doctorService.getById(id));
    }

    @GetMapping("/specializations")
    public ResponseEntity<List<SpecializationResponse>> getSpecializations() {
        return ResponseEntity.ok(doctorService.getAllSpecializations());
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<DoctorResponse> create(@Valid @RequestBody CreateDoctorRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(doctorService.create(request));
    }
}