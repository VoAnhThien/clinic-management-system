package com.clinic.service.impl;

import com.clinic.dto.appointment.*;
import com.clinic.entity.*;
import com.clinic.enums.AppointmentStatus;
import com.clinic.enums.SlotStatus;
import com.clinic.exception.*;
import com.clinic.repository.*;
import com.clinic.service.AppointmentBookingService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AppointmentServiceImpl implements AppointmentBookingService {

    private final AppointmentRepository appointmentRepository;
    private final AppointmentServiceRepository appointmentServiceRepository;
    private final TimeSlotRepository timeSlotRepository;
    private final PatientRepository patientRepository;
    private final UserRepository userRepository;
    private final ClinicServiceRepository clinicServiceRepository;

    @Override
    @Transactional
    public AppointmentResponse book(UUID bookedByUserId, AppointmentRequest req) {
        // 1. Load các entity cần thiết
        User bookedBy = userRepository.findById(bookedByUserId)
                .orElseThrow(() -> new ResourceNotFoundException("User", bookedByUserId));

        Patient patient = patientRepository.findById(req.getPatientId())
                .orElseThrow(() -> new ResourceNotFoundException("Patient", req.getPatientId()));

        // 2. Kiểm tra patient thuộc về user hiện tại
        if (!patient.getCreatedBy().getId().equals(bookedByUserId)
                && (patient.getUser() == null || !patient.getUser().getId().equals(bookedByUserId))) {
            throw new ForbiddenException("Bạn không có quyền đặt lịch cho bệnh nhân này");
        }

        // 3. Kiểm tra slot
        TimeSlot slot = timeSlotRepository.findById(req.getTimeSlotId())
                .orElseThrow(() -> new ResourceNotFoundException("TimeSlot", req.getTimeSlotId()));

        if (slot.getStatus() != SlotStatus.AVAILABLE) {
            throw new BadRequestException("Slot này không còn trống");
        }

        // 4. Kiểm tra trùng lịch
        if (appointmentRepository.existsByPatientIdAndTimeSlotId(
                req.getPatientId(), req.getTimeSlotId())) {
            throw new BadRequestException("Bệnh nhân đã có lịch hẹn ở slot này");
        }

        // 5. Tạo appointment
        Appointment appointment = Appointment.builder()
                .patient(patient)
                .timeSlot(slot)
                .doctor(slot.getSchedule().getDoctor())
                .clinic(slot.getSchedule().getClinic())
                .bookedBy(bookedBy)
                .reason(req.getReason())
                .status(AppointmentStatus.PENDING)
                .build();

        appointment = appointmentRepository.save(appointment);

        // 6. Gán dịch vụ nếu có
        List<AppointmentService> apptServices = new ArrayList<>();
        if (req.getServiceIds() != null && !req.getServiceIds().isEmpty()) {
            for (UUID serviceId : req.getServiceIds()) {
                ClinicService cs = clinicServiceRepository.findById(serviceId)
                        .orElseThrow(() -> new ResourceNotFoundException("Service", serviceId));
                apptServices.add(AppointmentService.builder()
                        .appointment(appointment)
                        .service(cs)
                        .quantity(1)
                        .unitPrice(cs.getBasePrice())
                        .build());
            }
            appointmentServiceRepository.saveAll(apptServices);
        }

        // 7. Đánh dấu slot đã booked
        slot.setStatus(SlotStatus.BOOKED);
        timeSlotRepository.save(slot);

        return toResponse(appointment, apptServices);
    }

    @Override
    public AppointmentResponse getById(UUID id, UUID currentUserId) {
        Appointment appt = appointmentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Appointment", id));

        // Chỉ người đặt, bác sĩ, hoặc admin mới xem được
        boolean isOwner = appt.getBookedBy().getId().equals(currentUserId);
        boolean isDoctor = appt.getDoctor().getUser().getId().equals(currentUserId);
        if (!isOwner && !isDoctor) {
            throw new ForbiddenException("Bạn không có quyền xem lịch hẹn này");
        }

        List<AppointmentService> services =
                appointmentServiceRepository.findByAppointmentId(id);
        return toResponse(appt, services);
    }

    @Override
    public Page<AppointmentResponse> getMyAppointments(UUID userId, Pageable pageable) {
        return appointmentRepository
                .findByBookedByIdOrderByBookedAtDesc(userId, pageable)
                .map(appt -> {
                    List<AppointmentService> services =
                            appointmentServiceRepository.findByAppointmentId(appt.getId());
                    return toResponse(appt, services);
                });
    }

    @Override
    @Transactional
    public AppointmentResponse cancel(UUID id, UUID currentUserId, CancelRequest req) {
        Appointment appt = appointmentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Appointment", id));

        if (!appt.getBookedBy().getId().equals(currentUserId)) {
            throw new ForbiddenException("Bạn không có quyền huỷ lịch hẹn này");
        }
        if (appt.getStatus() == AppointmentStatus.CANCELLED) {
            throw new BadRequestException("Lịch hẹn đã bị huỷ trước đó");
        }
        if (appt.getStatus() == AppointmentStatus.COMPLETED) {
            throw new BadRequestException("Không thể huỷ lịch hẹn đã hoàn thành");
        }

        appt.setStatus(AppointmentStatus.CANCELLED);
        appt.setCancelledAt(LocalDateTime.now());
        appt.setCancelReason(req.getCancelReason());

        // Giải phóng slot
        TimeSlot slot = appt.getTimeSlot();
        slot.setStatus(SlotStatus.AVAILABLE);
        timeSlotRepository.save(slot);

        appointmentRepository.save(appt);
        return toResponse(appt, appointmentServiceRepository.findByAppointmentId(id));
    }

    @Override
    @Transactional
    public AppointmentResponse confirm(UUID id) {
        Appointment appt = appointmentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Appointment", id));
        if (appt.getStatus() != AppointmentStatus.PENDING) {
            throw new BadRequestException("Chỉ có thể confirm lịch hẹn đang PENDING");
        }
        appt.setStatus(AppointmentStatus.CONFIRMED);
        return toResponse(appointmentRepository.save(appt),
                appointmentServiceRepository.findByAppointmentId(id));
    }

    @Override
    @Transactional
    public AppointmentResponse complete(UUID id) {
        Appointment appt = appointmentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Appointment", id));
        if (appt.getStatus() != AppointmentStatus.CONFIRMED) {
            throw new BadRequestException("Chỉ có thể complete lịch hẹn đang CONFIRMED");
        }
        appt.setStatus(AppointmentStatus.COMPLETED);
        return toResponse(appointmentRepository.save(appt),
                appointmentServiceRepository.findByAppointmentId(id));
    }

    // ── helpers ──────────────────────────────────────────────

    private AppointmentResponse toResponse(Appointment a, List<AppointmentService> services) {
        TimeSlot slot = a.getTimeSlot();
        return AppointmentResponse.builder()
                .id(a.getId())
                .status(a.getStatus().name().toLowerCase())
                .patientId(a.getPatient().getId())
                .patientName(a.getPatient().getFullName())
                .doctorId(a.getDoctor().getId())
                .doctorName(a.getDoctor().getFullName())
                .clinicId(a.getClinic().getId())
                .clinicName(a.getClinic().getName())
                .slotDate(slot.getSlotDate())
                .startTime(slot.getStartTime())
                .endTime(slot.getEndTime())
                .reason(a.getReason())
                .notes(a.getNotes())
                .bookedAt(a.getBookedAt())
                .cancelledAt(a.getCancelledAt())
                .cancelReason(a.getCancelReason())
                .services(services.stream().map(this::toServiceResponse).toList())
                .build();
    }

    private AppointmentServiceResponse toServiceResponse(AppointmentService as) {
        return AppointmentServiceResponse.builder()
                .serviceId(as.getService().getId())
                .serviceName(as.getService().getName())
                .quantity(as.getQuantity())
                .unitPrice(as.getUnitPrice())
                .lineTotal(as.getLineTotal())
                .build();
    }
}