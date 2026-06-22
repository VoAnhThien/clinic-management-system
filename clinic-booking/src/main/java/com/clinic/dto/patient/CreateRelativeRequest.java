package com.clinic.dto.patient;
import lombok.Data;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

@Data
public class CreateRelativeRequest {
    @NotBlank
    private String fullName;
    @NotNull
    private String relationToCreator; // spouse/child/parent/sibling/other
    private String nationalId;
    private LocalDate dateOfBirth;
    private String gender;
    private String phone;
    private String address;
    private String emergencyContact;
    private String bloodType;
    private String allergies;
}
