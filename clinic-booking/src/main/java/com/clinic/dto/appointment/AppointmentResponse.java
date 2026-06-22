package com.clinic.dto.appointment;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

@Data @Builder
public class AppointmentResponse {
    private UUID id;
    private String status;

    // Patient info
    private UUID patientId;
    private String patientName;

    // Doctor info
    private UUID doctorId;
    private String doctorName;

    // Clinic info
    private UUID clinicId;
    private String clinicName;

    // Slot info
    private LocalDate slotDate;
    private LocalTime startTime;
    private LocalTime endTime;

    private String reason;
    private String notes;
    private LocalDateTime bookedAt;
    private LocalDateTime cancelledAt;
    private String cancelReason;

    private List<AppointmentServiceResponse> services;
}