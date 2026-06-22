package com.clinic.service;

import com.clinic.dto.schedule.*;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public interface ScheduleService {
    ScheduleResponse createSchedule(ScheduleRequest request);
    List<ScheduleResponse> getDoctorSchedules(UUID doctorId);
    int generateSlots(UUID scheduleId, GenerateSlotsRequest request);
    List<TimeSlotResponse> getAvailableSlots(UUID doctorId, LocalDate date);
}