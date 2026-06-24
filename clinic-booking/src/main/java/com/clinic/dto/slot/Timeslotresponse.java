package com.clinic.dto.slot;

import com.clinic.enums.SlotStatus;
import lombok.Builder;
import lombok.Data;
import java.time.LocalTime;
import java.util.UUID;

@Data
@Builder
public class TimeSlotResponse {
    private UUID id;
    private String startTime;  // "HH:mm"
    private String endTime;    // "HH:mm"
    private SlotStatus status; // AVAILABLE, BOOKED, HELD, BLOCKED
    private boolean available;
}