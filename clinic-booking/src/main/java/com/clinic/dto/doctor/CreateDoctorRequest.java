package com.clinic.dto.doctor;

import jakarta.validation.constraints.*;
import lombok.*;
import java.util.Set;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateDoctorRequest {

    @NotBlank(message = "Họ tên không được để trống")
    private String fullName;

    @NotBlank(message = "Số chứng chỉ hành nghề không được để trống")
    private String licenseNumber;

    private String phone;

    private String biography;

    @Min(0)
    private Integer experienceYears;

    private String avatarUrl;

    // UUID của user account (role DOCTOR) gắn với bác sĩ này
    @NotNull(message = "userId không được để trống")
    private UUID userId;

    // Danh sách chuyên khoa (UUID)
    private Set<UUID> specializationIds;
}