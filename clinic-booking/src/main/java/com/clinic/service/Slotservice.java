package com.clinic.service;

import com.clinic.dto.slot.TimeSlotResponse;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public interface SlotService {
    /**
     * Trả về TẤT CẢ slot của bác sĩ trong ngày, kèm status.
     * Flutter dùng status để hiển thị slot tối/disabled.
     */
    List<TimeSlotResponse> getSlotsByDoctorAndDate(UUID doctorId, LocalDate date);
}