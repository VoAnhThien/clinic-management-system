package com.clinic.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import lombok.*;

import java.io.Serializable;
import java.util.UUID;

@Embeddable
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@EqualsAndHashCode
public class DoctorSpecializationId implements Serializable {

    @Column(name = "doctor_id")
    private UUID doctorId;

    @Column(name = "specialization_id")
    private UUID specializationId;
}