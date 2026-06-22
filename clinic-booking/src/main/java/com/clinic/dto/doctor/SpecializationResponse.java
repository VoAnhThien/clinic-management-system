package com.clinic.dto.doctor;

import lombok.Builder;
import lombok.Data;
import java.util.UUID;

@Data @Builder
public class SpecializationResponse {
    private UUID id;
    private String name;
    private String description;
}