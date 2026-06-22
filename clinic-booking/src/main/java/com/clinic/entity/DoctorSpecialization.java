package com.clinic.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "doctor_specializations")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class DoctorSpecialization {
    @EmbeddedId
    private DoctorSpecializationId id;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("doctorId")
    @JoinColumn(name = "doctor_id")
    private Doctor doctor;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("specializationId")
    @JoinColumn(name = "specialization_id")
    private Specialization specialization;
}