package com.clinic.repository;

import com.clinic.entity.TimeSlot;
import com.clinic.enums.SlotStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public interface TimeSlotRepository extends JpaRepository<TimeSlot, UUID> {

    // Lấy slots theo bác sĩ + ngày + status
    @Query("""
        SELECT ts FROM TimeSlot ts
        JOIN ts.schedule s
        WHERE s.doctor.id = :doctorId
        AND ts.slotDate = :date
        AND ts.status = :status
        ORDER BY ts.startTime
    """)
    List<TimeSlot> findByDoctorAndDateAndStatus(
            @Param("doctorId") UUID doctorId,
            @Param("date") LocalDate date,
            @Param("status") SlotStatus status
    );

    // Kiểm tra slot đã tồn tại chưa (tránh duplicate khi generate)
    boolean existsByScheduleIdAndSlotDateAndStartTime(
            UUID scheduleId, LocalDate slotDate, java.time.LocalTime startTime);

    // Giải phóng các slot held đã hết hạn
    @Modifying
    @Query("""
        UPDATE TimeSlot ts SET ts.status = 'AVAILABLE', ts.heldUntil = NULL, ts.heldBy = NULL
        WHERE ts.status = 'HELD' AND ts.heldUntil < :now
    """)
    int releaseExpiredHolds(@Param("now") LocalDateTime now);
}