package com.clinic.controller;

import com.clinic.dto.schedule.*;
import com.clinic.service.ScheduleService;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@RestController
@RequiredArgsConstructor
@Tag(name = "Schedule", description = "Lịch làm việc và time slot")
public class ScheduleController {

    private final ScheduleService scheduleService;

    // Public: xem lịch của bác sĩ
    @GetMapping("/doctors/{doctorId}/schedules")
    public ResponseEntity<List<ScheduleResponse>> getDoctorSchedules(
            @PathVariable UUID doctorId) {
        return ResponseEntity.ok(scheduleService.getDoctorSchedules(doctorId));
    }

    // Public: xem slot trống theo ngày
    @GetMapping("/doctors/{doctorId}/slots")
    public ResponseEntity<List<TimeSlotResponse>> getAvailableSlots(
            @PathVariable UUID doctorId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(scheduleService.getAvailableSlots(doctorId, date));
    }

    // Admin/Receptionist: tạo lịch
    @PostMapping("/schedules")
    @PreAuthorize("hasAnyRole('ADMIN', 'RECEPTIONIST')")
    public ResponseEntity<ScheduleResponse> createSchedule(
            @Valid @RequestBody ScheduleRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(scheduleService.createSchedule(request));
    }

    // Admin/Receptionist: generate slots
    @PostMapping("/schedules/{scheduleId}/generate-slots")
    @PreAuthorize("hasAnyRole('ADMIN', 'RECEPTIONIST')")
    public ResponseEntity<String> generateSlots(
            @PathVariable UUID scheduleId,
            @Valid @RequestBody GenerateSlotsRequest request) {
        int count = scheduleService.generateSlots(scheduleId, request);
        return ResponseEntity.ok("Đã tạo " + count + " time slots");
    }
}