package com.clinic.controller;
import com.clinic.dto.patient.*;
import com.clinic.service.PatientService;
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
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/patients")
@RequiredArgsConstructor
@Tag(name = "Patient", description = "Quản lý hồ sơ bệnh nhân")
public class PatientController {

    private final PatientService patientService;

    // ── Patient tự quản lý ───────────────────────────────────

    @GetMapping("/me")
    public ResponseEntity<PatientResponse> getMyProfile(
            @AuthenticationPrincipal UserDetails userDetails) {
        UUID userId = extractUserId(userDetails);
        return ResponseEntity.ok(patientService.getMyProfile(userId));
    }

    @PutMapping("/me")
    public ResponseEntity<PatientResponse> updateMyProfile(
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody UpdatePatientRequest request) {
        UUID userId = extractUserId(userDetails);
        return ResponseEntity.ok(patientService.updateMyProfile(userId, request));
    }

    @GetMapping("/my-profiles")
    public ResponseEntity<List<PatientResponse>> getMyProfiles(
            @AuthenticationPrincipal UserDetails userDetails) {
        UUID userId = extractUserId(userDetails);
        return ResponseEntity.ok(patientService.getMyProfiles(userId));
    }

    @PostMapping("/my-profiles")
    public ResponseEntity<PatientResponse> addRelative(
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody CreateRelativeRequest request) {
        UUID userId = extractUserId(userDetails);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(patientService.addRelative(userId, request));
    }

    @PutMapping("/my-profiles/{id}")
    public ResponseEntity<PatientResponse> updateRelative(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable UUID id,
            @Valid @RequestBody UpdatePatientRequest request) {
        UUID userId = extractUserId(userDetails);
        return ResponseEntity.ok(patientService.updateRelative(userId, id, request));
    }

    // ── Admin / Receptionist ─────────────────────────────────

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'RECEPTIONIST')")
    public ResponseEntity<Page<PatientResponse>> getAllPatients(
            @PageableDefault(size = 20, sort = "createdAt",
                             direction = Sort.Direction.DESC) Pageable pageable) {
        return ResponseEntity.ok(patientService.getAllPatients(pageable));
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'RECEPTIONIST', 'DOCTOR')")
    public ResponseEntity<PatientResponse> getPatientById(@PathVariable UUID id) {
        return ResponseEntity.ok(patientService.getPatientById(id));
    }

    // ── helper ───────────────────────────────────────────────

    private UUID extractUserId(UserDetails userDetails) {
        return UUID.fromString(userDetails.getUsername());
    }
}
