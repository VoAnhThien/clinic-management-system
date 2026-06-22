package com.clinic.dto.doctor;

import lombok.Builder;
import lombok.Data;
import java.util.List;
import java.util.UUID;

@Data @Builder
public class DoctorResponse {
    private UUID id;
    private UUID userId;
    private String fullName;
    private String licenseNumber;
    private String phone;
    private String biography;
    private Integer experienceYears;
    private String avatarUrl;
    private List<SpecializationResponse> specializations;
}