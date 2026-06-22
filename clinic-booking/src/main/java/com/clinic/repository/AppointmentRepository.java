package com.clinic.repository;

import com.clinic.entity.Appointment;
import com.clinic.enums.AppointmentStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.UUID;

public interface AppointmentRepository extends JpaRepository<Appointment, UUID> {

    // Lịch hẹn của patient (bao gồm cả đặt hộ)
    Page<Appointment> findByBookedByIdOrderByBookedAtDesc(UUID userId, Pageable pageable);

    // Lịch hẹn của doctor
    Page<Appointment> findByDoctorIdAndStatusOrderByBookedAtDesc(
            UUID doctorId, AppointmentStatus status, Pageable pageable);

    // Kiểm tra patient đã có appointment ở slot này chưa
    boolean existsByPatientIdAndTimeSlotId(UUID patientId, UUID timeSlotId);
}