package com.clinic.dto.schedule;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;

@Data @Builder
public class TimeSlotResponse {
    private UUID id;
    private LocalDate slotDate;
    private LocalTime startTime;
    private LocalTime endTime;
    private String status; 
     private boolean available;
}