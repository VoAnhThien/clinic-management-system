package com.clinic.dto.patient;
import lombok.Data;
import jakarta.validation.constraints.NotBlank;
import java.time.LocalDate;

@Data
public class UpdatePatientRequest {
    @NotBlank
    private String fullName;
    private String nationalId;
    private LocalDate dateOfBirth;
    private String gender;          // male/female/other
    private String phone;
    private String address;
    private String emergencyContact;
    private String bloodType;
    private String allergies;
}
