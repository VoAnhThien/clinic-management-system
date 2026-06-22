package com.clinic.repository;

import com.clinic.entity.AppointmentService;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface AppointmentServiceRepository extends JpaRepository<AppointmentService, UUID> {
    List<AppointmentService> findByAppointmentId(UUID appointmentId);
}