package com.clinic.dto.patient;
import lombok.Data;
import lombok.Builder;
import java.util.UUID;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data @Builder
public class PatientResponse {
    private UUID id;
    private UUID userId;
    private String fullName;
    private String nationalId;
    private LocalDate dateOfBirth;
    private String gender;
    private String phone;
    private String address;
    private String emergencyContact;
    private String bloodType;
    private String allergies;
    private String relationToCreator;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
