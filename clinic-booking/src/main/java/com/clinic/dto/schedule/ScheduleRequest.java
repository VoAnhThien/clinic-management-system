package com.clinic.dto.schedule;

import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.time.LocalTime;
import java.util.UUID;

@Data
public class ScheduleRequest {
    @NotNull private UUID doctorId;
    @NotNull private UUID clinicId;
    @NotNull private String dayOfWeek; // mon, tue, wed...
    @NotNull private LocalTime startTime;
    @NotNull private LocalTime endTime;
    @NotNull private Integer slotDurationMin; // 20 phút
}