package com.clinic.service;
import com.clinic.dto.appointment.AppointmentRequest;
import com.clinic.dto.appointment.AppointmentResponse;
import com.clinic.dto.appointment.CancelRequest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import java.util.UUID;

public interface AppointmentBookingService {
    AppointmentResponse book(UUID bookedByUserId, AppointmentRequest request);
    AppointmentResponse getById(UUID id, UUID currentUserId);
    Page<AppointmentResponse> getMyAppointments(UUID userId, Pageable pageable);
    AppointmentResponse cancel(UUID id, UUID currentUserId, CancelRequest request);
    // Doctor/Admin confirm
    AppointmentResponse confirm(UUID id);
    AppointmentResponse complete(UUID id);
}
