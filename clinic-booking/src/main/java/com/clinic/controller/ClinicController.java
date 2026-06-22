package com.clinic.controller;

import com.clinic.dto.clinic.ClinicRequest;
import com.clinic.dto.clinic.ClinicResponse;
import com.clinic.service.ClinicService;
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
import java.util.UUID;

@RestController
@RequestMapping("/clinics")
@RequiredArgsConstructor
@Tag(name = "Clinic", description = "Quản lý phòng khám")
public class ClinicController {

    private final ClinicService clinicService;

    @GetMapping
    public ResponseEntity<Page<ClinicResponse>> getAll(
            @PageableDefault(size = 20, sort = "name",
                             direction = Sort.Direction.ASC) Pageable pageable) {
        return ResponseEntity.ok(clinicService.getAll(pageable));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ClinicResponse> getById(@PathVariable UUID id) {
        return ResponseEntity.ok(clinicService.getById(id));
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ClinicResponse> create(
            @Valid @RequestBody ClinicRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(clinicService.create(request));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ClinicResponse> update(
            @PathVariable UUID id,
            @Valid @RequestBody ClinicRequest request) {
        return ResponseEntity.ok(clinicService.update(id, request));
    }
}