package com.clinic.dto.schedule;

import lombok.Builder;
import lombok.Data;
import java.time.LocalTime;
import java.util.UUID;

@Data @Builder
public class ScheduleResponse {
    private UUID id;
    private UUID doctorId;
    private String doctorName;
    private UUID clinicId;
    private String clinicName;
    private String dayOfWeek;
    private LocalTime startTime;
    private LocalTime endTime;
    private Integer slotDurationMin;
    private Boolean isActive;
}