package com.clinic.service.impl;

import com.clinic.dto.slot.TimeSlotResponse;
import com.clinic.entity.TimeSlot;
import com.clinic.enums.SlotStatus;
import com.clinic.repository.TimeSlotRepository;
import com.clinic.service.SlotService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class SlotServiceImpl implements SlotService {

    private final TimeSlotRepository timeSlotRepository;

    @Override
    public List<TimeSlotResponse> getSlotsByDoctorAndDate(UUID doctorId, LocalDate date) {
        return timeSlotRepository.findByDoctorAndDate(doctorId, date)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    private TimeSlotResponse toResponse(TimeSlot slot) {
        // Slot bị hold quá hạn → coi như available
        boolean isHeldExpired = slot.getStatus() == SlotStatus.HELD
                && slot.getHeldUntil() != null
                && slot.getHeldUntil().isBefore(LocalDateTime.now());

        SlotStatus effectiveStatus = isHeldExpired ? SlotStatus.AVAILABLE : slot.getStatus();

        return TimeSlotResponse.builder()
                .id(slot.getId())
                .startTime(slot.getStartTime().toString())   // "08:00"
                .endTime(slot.getEndTime().toString())       // "08:30"
                .status(effectiveStatus)
                .available(effectiveStatus == SlotStatus.AVAILABLE)
                .build();
    }
}