package com.clinic.dto.appointment;

import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.util.List;
import java.util.UUID;

@Data
public class AppointmentRequest {
    @NotNull private UUID patientId;    // có thể là người thân
    @NotNull private UUID timeSlotId;
    private String reason;
    private List<UUID> serviceIds;      // optional, có thể chọn dịch vụ
}