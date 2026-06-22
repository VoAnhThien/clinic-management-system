package com.clinic.repository;

import com.clinic.entity.DoctorSchedule;
import com.clinic.enums.DayOfWeekType;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface DoctorScheduleRepository extends JpaRepository<DoctorSchedule, UUID> {
    List<DoctorSchedule> findByDoctorIdAndIsActiveTrue(UUID doctorId);
    List<DoctorSchedule> findByDoctorIdAndDayOfWeekAndIsActiveTrue(
            UUID doctorId, DayOfWeekType dayOfWeek);
}