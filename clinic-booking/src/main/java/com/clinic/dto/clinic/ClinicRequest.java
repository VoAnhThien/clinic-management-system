package com.clinic.dto.clinic;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class ClinicRequest {
    @NotBlank private String name;
    @NotBlank private String address;
    private String phone;
    private String email;
    private String description;
}