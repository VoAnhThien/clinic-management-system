package com.clinic.service.impl;

import com.clinic.dto.schedule.*;
import com.clinic.entity.*;
import com.clinic.enums.DayOfWeekType;
import com.clinic.enums.SlotStatus;
import com.clinic.exception.BadRequestException;
import com.clinic.exception.ResourceNotFoundException;
import com.clinic.repository.*;
import com.clinic.service.ScheduleService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ScheduleServiceImpl implements ScheduleService {

    private final DoctorScheduleRepository scheduleRepository;
    private final TimeSlotRepository timeSlotRepository;
    private final DoctorRepository doctorRepository;
    private final ClinicRepository clinicRepository;

    @Override
    public ScheduleResponse createSchedule(ScheduleRequest req) {
        Doctor doctor = doctorRepository.findById(req.getDoctorId())
                .orElseThrow(() -> new ResourceNotFoundException("Doctor", req.getDoctorId()));
        Clinic clinic = clinicRepository.findById(req.getClinicId())
                .orElseThrow(() -> new ResourceNotFoundException("Clinic", req.getClinicId()));

        if (req.getEndTime().isBefore(req.getStartTime()) ||
                req.getEndTime().equals(req.getStartTime())) {
            throw new BadRequestException("end_time phải sau start_time");
        }
        if (req.getSlotDurationMin() <= 0) {
            throw new BadRequestException("Thời gian mỗi slot phải lớn hơn 0");
        }

        DoctorSchedule schedule = DoctorSchedule.builder()
                .doctor(doctor)
                .clinic(clinic)
                .dayOfWeek(DayOfWeekType.valueOf(req.getDayOfWeek().toUpperCase()))
                .startTime(req.getStartTime())
                .endTime(req.getEndTime())
                .slotDurationMin(req.getSlotDurationMin())
                .build();

        return toResponse(scheduleRepository.save(schedule));
    }

    @Override
    public List<ScheduleResponse> getDoctorSchedules(UUID doctorId) {
        return scheduleRepository.findByDoctorIdAndIsActiveTrue(doctorId)
                .stream().map(this::toResponse).toList();
    }

    @Override
    @Transactional
    public int generateSlots(UUID scheduleId, GenerateSlotsRequest req) {
        DoctorSchedule schedule = scheduleRepository.findById(scheduleId)
                .orElseThrow(() -> new ResourceNotFoundException("Schedule", scheduleId));

        if (req.getToDate().isBefore(req.getFromDate())) {
            throw new BadRequestException("toDate phải sau hoặc bằng fromDate");
        }
        if (req.getFromDate().plusDays(60).isBefore(req.getToDate())) {
            throw new BadRequestException("Chỉ được generate tối đa 60 ngày");
        }

        // Map DayOfWeekType sang DayOfWeek của Java
        java.time.DayOfWeek targetDay = mapDayOfWeek(schedule.getDayOfWeek());

        List<TimeSlot> slots = new ArrayList<>();
        LocalDate current = req.getFromDate();

        while (!current.isAfter(req.getToDate())) {
            if (current.getDayOfWeek() == targetDay) {
                // Sinh slots trong ngày theo slot_duration_min
                LocalTime slotStart = schedule.getStartTime();
                while (slotStart.plusMinutes(schedule.getSlotDurationMin())
                        .compareTo(schedule.getEndTime()) <= 0) {
                    LocalTime slotEnd = slotStart.plusMinutes(schedule.getSlotDurationMin());

                    // Tránh duplicate
                    if (!timeSlotRepository.existsByScheduleIdAndSlotDateAndStartTime(
                            scheduleId, current, slotStart)) {
                        slots.add(TimeSlot.builder()
                                .schedule(schedule)
                                .slotDate(current)
                                .startTime(slotStart)
                                .endTime(slotEnd)
                                .status(SlotStatus.AVAILABLE)
                                .build());
                    }
                    slotStart = slotEnd;
                }
            }
            current = current.plusDays(1);
        }

        timeSlotRepository.saveAll(slots);
        return slots.size();
    }

    @Override
    public List<TimeSlotResponse> getAvailableSlots(UUID doctorId, LocalDate date) {
        return timeSlotRepository
                .findByDoctorAndDateAndStatus(doctorId, date, SlotStatus.AVAILABLE)
                .stream().map(this::toSlotResponse).toList();
    }

    // ── helpers ──────────────────────────────────────────────

    private java.time.DayOfWeek mapDayOfWeek(DayOfWeekType type) {
        return switch (type) {
            case MON -> java.time.DayOfWeek.MONDAY;
            case TUE -> java.time.DayOfWeek.TUESDAY;
            case WED -> java.time.DayOfWeek.WEDNESDAY;
            case THU -> java.time.DayOfWeek.THURSDAY;
            case FRI -> java.time.DayOfWeek.FRIDAY;
            case SAT -> java.time.DayOfWeek.SATURDAY;
            case SUN -> java.time.DayOfWeek.SUNDAY;
        };
    }

    private ScheduleResponse toResponse(DoctorSchedule s) {
        return ScheduleResponse.builder()
                .id(s.getId())
                .doctorId(s.getDoctor().getId())
                .doctorName(s.getDoctor().getFullName())
                .clinicId(s.getClinic().getId())
                .clinicName(s.getClinic().getName())
                .dayOfWeek(s.getDayOfWeek().name().toLowerCase())
                .startTime(s.getStartTime())
                .endTime(s.getEndTime())
                .slotDurationMin(s.getSlotDurationMin())
                .isActive(s.getIsActive())
                .build();
    }

    private TimeSlotResponse toSlotResponse(TimeSlot ts) {
        return TimeSlotResponse.builder()
                .id(ts.getId())
                .slotDate(ts.getSlotDate())
                .startTime(ts.getStartTime())
                .endTime(ts.getEndTime())
                .status(ts.getStatus().name().toLowerCase())
                .build();
    }
}