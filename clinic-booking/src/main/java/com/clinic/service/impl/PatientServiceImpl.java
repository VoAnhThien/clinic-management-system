package com.clinic.service.impl;
import com.clinic.dto.patient.*;
import com.clinic.entity.*;
import com.clinic.enums.RelationType;
import com.clinic.enums.GenderType;
import com.clinic.entity.Patient;
import com.clinic.entity.User;
import com.clinic.exception.*;
import com.clinic.repository.*;
import com.clinic.service.PatientService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class PatientServiceImpl implements PatientService {

    private final PatientRepository patientRepository;
    private final UserRepository userRepository;

    @Override
    public PatientResponse getMyProfile(UUID userId) {
        Patient patient = patientRepository.findByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Patient profile not found"));
        return toResponse(patient);
    }

    @Override
    public PatientResponse updateMyProfile(UUID userId, UpdatePatientRequest req) {
        Patient patient = patientRepository.findByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Patient profile not found"));
        applyUpdate(patient, req);
        return toResponse(patientRepository.save(patient));
    }

    @Override
    public List<PatientResponse> getMyProfiles(UUID userId) {
        return patientRepository.findByCreatedById(userId)
                .stream().map(this::toResponse).toList();
    }

    @Override
    public PatientResponse addRelative(UUID userId, CreateRelativeRequest req) {
        User creator = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        RelationType relation = RelationType.valueOf(req.getRelationToCreator().toUpperCase());
        if (relation == RelationType.SELF) {
            throw new BadRequestException("Cannot add another 'self' profile");
        }

        Patient relative = Patient.builder()
                .createdBy(creator)
                .relationToCreator(relation)
                .fullName(req.getFullName())
                .nationalId(req.getNationalId())
                .dateOfBirth(req.getDateOfBirth())
                .gender(req.getGender() != null ? GenderType.valueOf(req.getGender().toUpperCase()) : null)
                .phone(req.getPhone())
                .address(req.getAddress())
                .emergencyContact(req.getEmergencyContact())
                .bloodType(req.getBloodType())
                .allergies(req.getAllergies())
                .build();

        return toResponse(patientRepository.save(relative));
    }

    @Override
    public PatientResponse updateRelative(UUID userId, UUID patientId, UpdatePatientRequest req) {
        Patient patient = patientRepository.findById(patientId)
                .orElseThrow(() -> new ResourceNotFoundException("Patient not found"));

        // Chỉ người tạo mới được sửa
        if (!patient.getCreatedBy().getId().equals(userId)) {
            throw new ForbiddenException("You don't have permission to update this profile");
        }
        if (patient.getRelationToCreator() == RelationType.SELF) {
            throw new BadRequestException("Use /me endpoint to update your own profile");
        }

        applyUpdate(patient, req);
        return toResponse(patientRepository.save(patient));
    }

    @Override
    public Page<PatientResponse> getAllPatients(Pageable pageable) {
        return patientRepository.findAll(pageable).map(this::toResponse);
    }

    @Override
    public PatientResponse getPatientById(UUID patientId) {
        return toResponse(patientRepository.findById(patientId)
                .orElseThrow(() -> new ResourceNotFoundException("Patient not found")));
    }

    // ── helpers ──────────────────────────────────────────────

    private void applyUpdate(Patient p, UpdatePatientRequest req) {
        p.setFullName(req.getFullName());
        p.setNationalId(req.getNationalId());
        p.setDateOfBirth(req.getDateOfBirth());
        p.setGender(req.getGender() != null ? GenderType.valueOf(req.getGender().toUpperCase()) : null);
        p.setPhone(req.getPhone());
        p.setAddress(req.getAddress());
        p.setEmergencyContact(req.getEmergencyContact());
        p.setBloodType(req.getBloodType());
        p.setAllergies(req.getAllergies());
    }

    private PatientResponse toResponse(Patient p) {
        return PatientResponse.builder()
                .id(p.getId())
                .userId(p.getUser() != null ? p.getUser().getId() : null)
                .fullName(p.getFullName())
                .nationalId(p.getNationalId())
                .dateOfBirth(p.getDateOfBirth())
                .gender(p.getGender() != null ? p.getGender().name().toLowerCase() : null)
                .phone(p.getPhone())
                .address(p.getAddress())
                .emergencyContact(p.getEmergencyContact())
                .bloodType(p.getBloodType())
                .allergies(p.getAllergies())
                .relationToCreator(p.getRelationToCreator().name().toLowerCase())
                .createdAt(p.getCreatedAt())
                .updatedAt(p.getUpdatedAt())
                .build();
    }
}