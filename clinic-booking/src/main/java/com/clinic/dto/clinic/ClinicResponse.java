package com.clinic.dto.clinic;

import lombok.Builder;
import lombok.Data;
import java.util.UUID;

@Data @Builder
public class ClinicResponse {
    private UUID id;
    private String name;
    private String address;
    private String phone;
    private String email;
    private String description;
    private Boolean isActive;
}